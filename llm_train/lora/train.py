#!/usr/bin/env python3
"""
train.py
QLoRA + LoRA visual-adapter training starter for Qwen-14B on a single 24GB GPU.
Design: keep the LLM in 4-bit (bitsandbytes) and train a small visual adapter + LoRA on cross-attention modules.

This is a practical, minimal starter. You will need to adapt dataset loading and possibly target modules to your model.
"""

import argparse
import os
from dataclasses import dataclass
from typing import Dict, Any, Optional

import torch
from torch import nn
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    AutoFeatureExtractor,
    TrainingArguments,
    Trainer,
)

try:
    from peft import get_peft_model, LoraConfig, TaskType
except Exception:
    # keep import error lazy; clearer message later
    get_peft_model = None
    LoraConfig = None
    TaskType = None


# Lightweight wrapper that injects projected image embeddings in place of a special token (<image>)
class VisionAdapterModel(nn.Module):
    def __init__(self, base_model, vision_encoder, tokenizer, image_token="<image>"):
        super().__init__()
        self.base_model = base_model
        self.vision_encoder = vision_encoder
        self.tokenizer = tokenizer
        self.image_token_id = tokenizer.convert_tokens_to_ids(image_token)
        self.image_proj = nn.Linear(self.vision_encoder.config.hidden_size, base_model.get_input_embeddings().embedding_dim)

    def forward(self, input_ids=None, attention_mask=None, pixel_values=None, labels=None, **kwargs):
        # compute token embeddings
        inputs_embeds = None
        if input_ids is not None:
            inputs_embeds = self.base_model.get_input_embeddings()(input_ids)

        # if there is an image, get embedding and project
        if pixel_values is not None:
            # vision encoder forward (expecting pixel_values shape)
            vision_outputs = self.vision_encoder(pixel_values=pixel_values)
            # many vision models return pooled output or last_hidden_state; try pooled
            if hasattr(vision_outputs, "pooler_output") and vision_outputs.pooler_output is not None:
                v = vision_outputs.pooler_output
            else:
                # fall back to mean pooling of last_hidden_state
                last = getattr(vision_outputs, "last_hidden_state", None)
                if last is None:
                    raise ValueError("Vision encoder did not return usable embeddings")
                v = last.mean(dim=1)
            img_embed = self.image_proj(v)  # (batch, embed_dim)

            if inputs_embeds is None:
                raise ValueError("input_ids required when providing pixel_values")

            # replace token embeddings at positions of image token with img_embed
            # supports single <image> token per example
            mask = (input_ids == self.image_token_id)
            for i in range(inputs_embeds.size(0)):
                pos = torch.where(mask[i])[0]
                if pos.numel() == 0:
                    continue
                # if multiple positions, broadcast the same embedding
                for p in pos:
                    inputs_embeds[i, p, :] = img_embed[i]

        # call base model with inputs_embeds
        outputs = self.base_model(
            inputs_embeds=inputs_embeds,
            attention_mask=attention_mask,
            labels=labels,
            return_dict=True,
        )
        return outputs


@dataclass
class DataCollatorForVisionPrefix:
    tokenizer: AutoTokenizer
    feature_extractor: Any
    max_length: int = 2048

    def __call__(self, batch: Dict[str, Any]) -> Dict[str, Any]:
        # batch: list of dicts with keys: image (PIL or array) or pixel_values, prompt (str), response (str)
        texts = []
        pixel_values = []
        for ex in batch:
            # we expect the prompt to contain the <image> token where appropriate
            prompt = ex["prompt"]
            resp = ex.get("response", "")
            text = prompt + resp
            texts.append(text)
            if "image" in ex and ex["image"] is not None:
                pixel_values.append(ex["image"])
            elif "pixel_values" in ex:
                pixel_values.append(ex["pixel_values"])
            else:
                pixel_values.append(None)

        # tokenize
        model_inputs = self.tokenizer(texts, return_tensors="pt", padding=True, truncation=True, max_length=self.max_length)

        # process images to pixel_values tensor if provided
        # feature_extractor expects list of images
        if any(p is not None for p in pixel_values):
            imgs = [p if p is not None else 0 for p in pixel_values]
            # feature_extractor will fail for scalar 0; replace None with a zero image dtype handled later
            real_imgs = [p for p in pixel_values if p is not None]
            # naive: call feature_extractor on real images and then map back; for simplicity assume all provided
            pv = self.feature_extractor(pixel_values=real_imgs, return_tensors="pt").pixel_values
            # if some examples had no image, pad with zeros
            if len(real_imgs) != len(pixel_values):
                # create zeros for missing
                zero = torch.zeros_like(pv[0:1])
                full = []
                ri = 0
                for p in pixel_values:
                    if p is None:
                        full.append(zero[0])
                    else:
                        full.append(pv[ri])
                        ri += 1
                pixel_values = torch.stack(full, dim=0)
            else:
                pixel_values = pv
            model_inputs["pixel_values"] = pixel_values

        return model_inputs


def build_prompt(image_token: str, instruction: str) -> str:
    # places the image token at start of instruction; you can customize prompt template
    return f"{image_token} {instruction}\n\n### Response:\n"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name_or_path", type=str, required=True)
    parser.add_argument("--vision_encoder", type=str, default="openai/clip-vit-large-patch14")
    parser.add_argument("--dataset_path", type=str, required=False, help="path to jsonl data with fields: image, instruction, response")
    parser.add_argument("--output_dir", type=str, default="./out")
    parser.add_argument("--per_device_train_batch_size", type=int, default=1)
    parser.add_argument("--gradient_accumulation_steps", type=int, default=8)
    parser.add_argument("--max_seq_length", type=int, default=2048)
    parser.add_argument("--lora_r", type=int, default=16)
    parser.add_argument("--lora_alpha", type=int, default=32)
    parser.add_argument("--lora_dropout", type=float, default=0.05)
    parser.add_argument("--train_steps", type=int, default=1000)
    return parser.parse_args()


def main():
    args = parse_args()

    # tokenizer
    tokenizer = AutoTokenizer.from_pretrained(args.model_name_or_path, use_fast=False)
    # add image token if missing
    image_token = "<image>"
    if image_token not in tokenizer.get_vocab():
        tokenizer.add_special_tokens({"additional_special_tokens": [image_token]})

    # load vision encoder and feature extractor
    feature_extractor = AutoFeatureExtractor.from_pretrained(args.vision_encoder)
    vision_encoder = None
    try:
        vision_encoder = AutoModelForCausalLM.from_pretrained  # dummy to silence linter
    except Exception:
        pass
    # actually load a ViT/CLIP image encoder
    from transformers import AutoModel

    vision_encoder = AutoModel.from_pretrained(args.vision_encoder)

    # load LLM - we rely on accelerate/transformers/bitsandbytes flags externally; here we assume environment handles 4-bit
    model = AutoModelForCausalLM.from_pretrained(
        args.model_name_or_path,
        low_cpu_mem_usage=True,
        trust_remote_code=True,
    )

    # resize token embeddings if tokenizer changed
    model.resize_token_embeddings(len(tokenizer))

    # wrap with vision adapter
    wrapped = VisionAdapterModel(model, vision_encoder, tokenizer, image_token=image_token)

    # apply PEFT LoRA if available
    if get_peft_model is None:
        raise RuntimeError("peft package not found; install 'peft' to apply LoRA")

    peft_config = LoraConfig(
        r=args.lora_r,
        lora_alpha=args.lora_alpha,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
        lora_dropout=args.lora_dropout,
        bias="none",
        task_type=TaskType.CAUSAL_LM,
    )

    model = get_peft_model(wrapped, peft_config)

    # Dataset loading: user should supply a jsonl where each line: {"image": "/abs/path.jpg", "instruction": "...", "response": "..."}
    from datasets import load_dataset

    if args.dataset_path is None:
        raise ValueError("Please pass --dataset_path pointing to a jsonl file with image/instruction/response")

    ds = load_dataset("json", data_files=args.dataset_path, split="train")

    # prepare dataset records
    def preprocess(example):
        inst = example.get("instruction", "")
        resp = example.get("response", "")
        image = example.get("image", None)
        prompt = build_prompt(image_token, inst)
        return {"prompt": prompt, "response": resp, "image": image}

    ds = ds.map(preprocess)

    # feature extractor expects PIL images; let datasets handle image loading if path provided
    from datasets import Features, Value, Image, Sequence

    # transform each example: load image into 'image' column as PIL
    if isinstance(ds.features.get("image"), (Image,)):
        # already an image feature
        pass
    else:
        # try to cast
        ds = ds.cast(Features({"image": Image()}))

    data_collator = DataCollatorForVisionPrefix(tokenizer=tokenizer, feature_extractor=feature_extractor, max_length=args.max_seq_length)

    training_args = TrainingArguments(
        output_dir=args.output_dir,
        per_device_train_batch_size=args.per_device_train_batch_size,
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        fp16=False,
        bf16=True,
        max_steps=args.train_steps,
        logging_steps=20,
        save_steps=1000,
        remove_unused_columns=False,
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=ds,
        data_collator=data_collator,
        tokenizer=tokenizer,
    )

    trainer.train()
    trainer.save_model(args.output_dir)


if __name__ == "__main__":
    main()
