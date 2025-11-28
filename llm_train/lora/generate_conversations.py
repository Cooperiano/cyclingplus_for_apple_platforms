#!/usr/bin/env python3
"""
generate_conversations.py

用本地 Qwen-14B-Chat（或兼容 HF 模型）生成多轮对话数据。
输出：raw_dialogs.jsonl，每行是一个对话（list of {role, text}）

用法示例：
python generate_conversations.py --n_dialogs 100 --turns 6 --out raw_dialogs.jsonl
"""
import argparse
import json
import os
import random
from tqdm import trange

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

PROMPT_TEMPLATE = (
    "下面是一段用户与助手的对话，注意角色前缀为“用户：”和“助手：”。请以助手身份回答用户的最后一条消息。\n\n{history}\n用户：{user}\n助手："
)

DEFAULT_MODEL_PATH = "/home/julian/.cache/modelscope/hub/models/Qwen/Qwen-14B-Chat"


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--model_path', type=str, default=DEFAULT_MODEL_PATH)
    p.add_argument('--n_dialogs', type=int, default=100)
    p.add_argument('--turns', type=int, default=6, help='每个对话的轮数（用户+助手 计为 1 轮）')
    p.add_argument('--max_new_tokens', type=int, default=128)
    p.add_argument('--temperature', type=float, default=0.8)
    p.add_argument('--top_p', type=float, default=0.95)
    p.add_argument('--seed', type=int, default=42)
    p.add_argument('--out', type=str, default='raw_dialogs.jsonl')
    p.add_argument('--batch', type=int, default=1)
    return p.parse_args()


def build_history_text(history):
    # history: list of dicts {role: 'user'|'assistant', text: str}
    lines = []
    for m in history:
        prefix = '用户：' if m['role'] == 'user' else '助手：'
        lines.append(f"{prefix}{m['text']}")
    return '\n'.join(lines)


def main():
    args = parse_args()
    random.seed(args.seed)
    torch.manual_seed(args.seed)

    tokenizer = AutoTokenizer.from_pretrained(args.model_path, trust_remote_code=True, local_files_only=True)
    model = AutoModelForCausalLM.from_pretrained(args.model_path, trust_remote_code=True, local_files_only=True, device_map='auto')
    model.config.use_cache = False
    if hasattr(model, 'generation_config'):
        model.generation_config.use_cache = False

    out_f = open(args.out, 'w', encoding='utf-8')

    for i in trange(args.n_dialogs, desc='dialogs'):
        # seed per dialog for reproducibility
        if args.seed is not None:
            torch.manual_seed(args.seed + i)
            random.seed(args.seed + i)

        history = []
        # start with a user prompt seed (could be randomized or from a seed list)
        # для中文-friendly seeds
        starter = random.choice([
            '帮我写一封给老板的请假邮件，说明需要两天时间处理家庭事务。',
            '用简短语言推荐三本入门机器学习的书籍并说明原因。',
            '帮我模拟一段面试问答，职位是机器学习工程师。',
            '如何把我的论文摘要写得更清晰？下面是摘要草稿：...',
            '请用非专业语言解释量子计算的基本概念。',
        ])
        user_msg = starter
        for t in range(args.turns):
            # build input prompt with history
            history_text = build_history_text(history)
            prompt = PROMPT_TEMPLATE.format(history=history_text, user=user_msg)
            inputs = tokenizer(prompt, return_tensors='pt')
            input_ids = inputs['input_ids'].to(model.device)
            attention_mask = inputs.get('attention_mask', torch.ones_like(input_ids)).to(model.device)

            gen = model.generate(
                input_ids=input_ids,
                attention_mask=attention_mask,
                max_new_tokens=args.max_new_tokens,
                do_sample=True,
                top_p=args.top_p,
                temperature=args.temperature,
                use_cache=False,
            )
            resp = tokenizer.decode(gen[0], skip_special_tokens=True)
            # decode returns full prompt+reply; extract assistant reply after the last '助手：'
            if '助手：' in resp:
                assistant_text = resp.split('助手：')[-1].strip()
            else:
                assistant_text = resp

            history.append({'role':'user', 'text': user_msg})
            history.append({'role':'assistant', 'text': assistant_text})

            # next user message: either a small follow-up (random) or stop if reached turns
            if t < args.turns - 1:
                # simple heuristic: ask clarifying or follow-up question
                followups = [
                    '可以更具体一点吗？',
                    '能给个例子吗？',
                    '那具体怎么做？',
                    '能否换个风格写？',
                    '还有其他建议吗？',
                ]
                user_msg = random.choice(followups)

        # write dialog to file
        out_f.write(json.dumps(history, ensure_ascii=False) + '\n')

    out_f.close()
    print('Saved to', args.out)


if __name__ == '__main__':
    main()
