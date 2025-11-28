#!/usr/bin/env python3
"""
process_dataset.py

将 generate_conversations.py 生成的 raw_dialogs.jsonl 转换为 LoRA/QLoRA SFT 训练所需的 jsonl 格式。
输出示例行： {"instruction": "用户: ...\n助手: ...\n用户: X", "response": "助手: ..."}

用法：
python process_dataset.py --in raw_dialogs.jsonl --out data.jsonl --turns 3
"""
import argparse
import json


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('--in', dest='infile', type=str, required=True)
    p.add_argument('--out', type=str, default='data.jsonl')
    p.add_argument('--turns', type=int, default=3, help='保留最近多少轮作为上下文')
    return p.parse_args()


def build_example(history, turns):
    # history: list of {role, text}
    # we will take last `turns` user messages + preceding assistant replies to build instruction/response
    # find last assistant message and the preceding user message
    seq = history[-(turns*2):] if len(history) >= turns*2 else history
    # build instruction as the conversation up to last user message
    # response is the assistant reply following that user
    instruction_parts = []
    response = ''
    # assume alternating user/assistant starting with user
    for i, m in enumerate(seq[:-1]):
        if m['role'] == 'user':
            instruction_parts.append('用户: ' + m['text'])
        else:
            instruction_parts.append('助手: ' + m['text'])
    # last element should be assistant reply
    last = seq[-1]
    if last['role'] == 'assistant':
        response = last['text']
    else:
        # no assistant reply; set empty
        response = ''

    instruction = '\n'.join(instruction_parts).strip()
    return {'instruction': instruction, 'response': response}


def main():
    args = parse_args()
    with open(args.infile, 'r', encoding='utf-8') as fin, open(args.out, 'w', encoding='utf-8') as fout:
        for line in fin:
            hist = json.loads(line)
            ex = build_example(hist, args.turns)
            fout.write(json.dumps(ex, ensure_ascii=False) + '\n')
    print('Saved to', args.out)


if __name__ == '__main__':
    main()
