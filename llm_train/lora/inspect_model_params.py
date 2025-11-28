#!/usr/bin/env python3
"""
inspect_model_params.py

列出 Hugging Face Transformers 模型的所有参数名（支持 Qwen-14B、Llama、Qwen-VL 等），用于确定 LoRA target_modules。

用法：
  python inspect_model_params.py --model_name_or_path qwen-14b
  python inspect_model_params.py --model_name_or_path meta-llama/Llama-2-14b-chat-hf

可选参数：--show-structure（显示模块层级）
"""
import argparse
from transformers import AutoModelForCausalLM

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model_name_or_path', type=str, required=True, help='HF模型名称或本地路径')
    parser.add_argument('--show_structure', action='store_true', help='显示模块层级')
    args = parser.parse_args()

    print(f"加载模型: {args.model_name_or_path}")
    model = AutoModelForCausalLM.from_pretrained(args.model_name_or_path, trust_remote_code=True)

    print("\n参数名（可用于 target_modules）：")
    for name, param in model.named_parameters():
        print(name)

    if args.show_structure:
        print("\n模块层级（可用于 target_modules）：")
        for name, module in model.named_modules():
            print(name)

if __name__ == '__main__':
    main()
