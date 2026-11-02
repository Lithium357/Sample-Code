#!/usr/bin/env python3
"""Recount source with the named BPE encoding. Install tiktoken first.

python -m pip install tiktoken
python tools/count_tokens.py --encoding cl100k_base
python tools/count_tokens.py --encoding o200k_base

Only source paths in manifest.json count; README, generators and reports do not.
Tokens are summed per file, rather than tokenizing a concatenation with separators.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import tiktoken

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--encoding',default='cl100k_base')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    manifest = json.loads((root/'manifest.json').read_text(encoding='utf-8'))
    encoding = tiktoken.get_encoding(args.encoding)
    totals = defaultdict(int)
    for entry in manifest:
        text = (root/entry['path']).read_text(encoding='utf-8')
        totals[entry['language']] += len(encoding.encode(text,disallowed_special=()))
    print(f'Encoding: {args.encoding}; source + comments + embedded fixtures')
    for language,total in totals.items():
        print(f'{language:12} {total:7,}')
    print(f'{"TOTAL":12} {sum(totals.values()):7,}')

if __name__ == '__main__':
    main()
