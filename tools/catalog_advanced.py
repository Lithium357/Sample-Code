#!/usr/bin/env python3
"""Refresh advanced source sizes and hashes. Requires tiktoken.
The advanced collection is separately authored; the basic corpus generators
never overwrite it. Counts include source comments and embedded self-checks.
"""
from collections import Counter
import hashlib
import json
from pathlib import Path
import tiktoken

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {'nim':'.nim','cmd':'.cmd','assembly':'.asm','powershell':'.ps1',
              'sql':'.sql','bash':'.sh','rust':'.rs','ruby':'.rb','go':'.go','php':'.php'}

def main():
    encoding = tiktoken.get_encoding('cl100k_base')
    entries = []
    totals = Counter()
    for language,extension in EXTENSIONS.items():
        for path in sorted((ROOT/'advanced'/language).glob('*'+extension)):
            data = path.read_bytes()
            count = len(encoding.encode(path.read_text(encoding='utf-8'),disallowed_special=()))
            entries.append({'path':path.relative_to(ROOT).as_posix(),'language':language,
                            'tokens':count,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
            totals[language] += count
    report = {'encoding':'cl100k_base','source_files':len(entries),'tokens':sum(totals.values()),
              'tokens_by_language':dict(totals),'files':entries}
    (ROOT/'advanced'/'manifest.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))

if __name__ == '__main__':
    main()
