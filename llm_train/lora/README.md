QLoRA + LoRA visual adapter starter for Qwen-14B (single RTX 4090, 24GB)

What this repo provides
- `train.py`: starter script to fine-tune Qwen-14B with a small visual adapter + LoRA (SFT style). The script expects a JSONL dataset where each line is {"image": "/abs/path.jpg", "instruction": "...", "response": "..."}.
- `requirements.txt`: python deps.

High-level notes
- The script keeps the LLM weights untouched (loaded in low-memory mode) and trains small adapters + LoRA. It uses a single GPU workflow with Accelerate/Trainer.
- The tokenizer gets a special token `<image>` that the model will use as a placeholder; the wrapper replaces that token's embedding with a projected image embedding at runtime.

Quick start
1) Install deps (in a Python venv):

```bash
python -m pip install -r requirements.txt
```

2) Login to Hugging Face (if model is gated):

```bash
pip install huggingface_hub
huggingface-cli login
```

3) Prepare data: a JSONL file where each line is a JSON object with keys `image` (path), `instruction` and `response`.

4) Run training (use `accelerate launch` recommended):

```bash
accelerate launch train.py \
  --model_name_or_path qwen-14b \
  --vision_encoder openai/clip-vit-large-patch14 \
  --dataset_path /path/to/data.jsonl \
  --output_dir ./out \
  --per_device_train_batch_size 1 \
  --gradient_accumulation_steps 12 \
  --max_seq_length 2048 \
  --train_steps 2000 \
  --lora_r 16 --lora_alpha 32 --lora_dropout 0.05
```

Notes & caveats
- This is a starter. You will likely need to adapt `target_modules` for LoRA to match your model's internal naming and enable bitsandbytes/4-bit loading via `accelerate` config (or `transformers` kwargs). Example flags for 4-bit loading are supplied in the initial guidance you received.
- `gguf` weights (llama.cpp) are not usable for training; use PyTorch or `safetensors` weights.
- If you want a simpler pipeline (no adapter), you can extract image captions/embeddings via CLIP and prepend text to the prompt instead of architecture changes.

Next steps
- I can adapt `train.py` to a specific HF model name (e.g., `Qwen-14B` HF repo path) and tailor `target_modules` or add DeepSpeed/Offload examples. Tell me which model path you plan to use and whether you prefer 4-bit or 8-bit base.
