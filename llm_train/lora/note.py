import argparse
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model_path', type=str, default='/home/julian/.cache/modelscope/hub/models/Qwen/Qwen-14B-Chat')
    ap.add_argument('--prompt', type=str, default='你好，介绍一下你自己。')
    ap.add_argument('--max_new_tokens', type=int, default=128)
    ap.add_argument('--temperature', type=float, default=0.8)
    ap.add_argument('--top_p', type=float, default=0.9)
    ap.add_argument('--seed', type=int, default=42)
    ap.add_argument('--no_sample', action='store_true', help='关闭采样，使用贪心')
    ap.add_argument('--half', action='store_true', help='强制 fp16 (若显存较紧)')
    return ap.parse_args()

def main():
    args = parse_args()
    torch.manual_seed(args.seed)

    tokenizer = AutoTokenizer.from_pretrained(args.model_path, trust_remote_code=True, local_files_only=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    load_kwargs = dict(trust_remote_code=True, local_files_only=True, device_map='auto')
    model = AutoModelForCausalLM.from_pretrained(args.model_path, **load_kwargs).eval()
    if args.half and hasattr(model, 'half'):
        model.half()

    # 禁止使用缓存避免 Qwen 某些版本 past_key_values Bug
    model.config.use_cache = False
    if hasattr(model, 'generation_config'):
        model.generation_config.use_cache = False

    inputs = tokenizer(args.prompt, return_tensors='pt')
    input_ids = inputs['input_ids'].to(model.device)
    if 'attention_mask' in inputs:
        attention_mask = inputs['attention_mask'].to(model.device)
    else:
        attention_mask = torch.ones_like(input_ids)

    gen_kwargs = dict(
        max_new_tokens=args.max_new_tokens,
        use_cache=False,
    )
    if args.no_sample:
        gen_kwargs.update(dict(do_sample=False))
    else:
        gen_kwargs.update(dict(do_sample=True, top_p=args.top_p, temperature=args.temperature))

    with torch.no_grad():
        out = model.generate(input_ids=input_ids, attention_mask=attention_mask, **gen_kwargs)

    print('[Prompt]', args.prompt)
    print('[Generate]', tokenizer.decode(out[0], skip_special_tokens=True))

if __name__ == '__main__':
    main()