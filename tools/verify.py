#!/usr/bin/env python3
"""Run standalone examples with installed runtimes; never install anything.

Examples:
    python tools/verify.py
    python tools/verify.py --language rust --require-tools
    python tools/verify.py --language sql --report validation-local.json

Compiler outputs go into a temporary directory, outside the source tree.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ['nim', 'cmd', 'assembly', 'powershell', 'sql', 'bash', 'rust', 'ruby', 'go', 'php']
NIM_BACKEND = 'c'

def run(command, cwd, timeout=45):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f'{command[0]} exited {result.returncode}\n{result.stdout}\n{result.stderr}')
    return result.stdout.strip()

def tool(name):
    return shutil.which(name)

def required(language):
    return {'nim':['nim'], 'cmd':['cmd'] if os.name == 'nt' else ['cmd.exe'],
            'assembly':['nasm','ld'], 'powershell':['pwsh'], 'sql':[],
            'bash':['bash'], 'rust':['rustc'], 'ruby':['ruby'], 'go':['go'], 'php':['php']}[language]

def verify_file(entry, temp):
    language = entry['language']
    path = ROOT / entry['path']
    binary = temp / ('demo.exe' if os.name == 'nt' else 'demo')
    if language == 'sql':
        with sqlite3.connect(':memory:') as connection:
            connection.executescript(path.read_text(encoding='utf-8'))
            count = connection.execute('SELECT COUNT(*) FROM checks').fetchone()[0]
            if count != entry['fixtures']:
                raise AssertionError(f'expected {entry["fixtures"]} checks, got {count}')
            if connection.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
                raise AssertionError('SQLite integrity check failed')
            if connection.execute('PRAGMA foreign_key_check').fetchall():
                raise AssertionError('SQLite foreign key check failed')
        return f'{count} SQL result checks passed'
    if language == 'rust':
        run([tool('rustc'),'--edition=2021','-A','unused_parens',str(path),'-o',str(binary)],temp)
        return run([str(binary)],temp)
    if language == 'nim':
        if NIM_BACKEND == 'js':
            output = temp / 'demo.js'
            run([tool('nim'),'js','--hints:off','-o:'+str(output),str(path)],temp)
            return run([tool('node'),str(output)],temp)
        return run([tool('nim'),'c','-r','--hints:off','--nimcache:'+str(temp/'nimcache'),'-o:'+str(binary),str(path)],temp)
    if language == 'assembly':
        obj = temp / 'demo.o'
        run([tool('nasm'),'-f','elf64',str(path),'-o',str(obj)],temp)
        run([tool('ld'),str(obj),'-o',str(binary)],temp)
        run([str(binary)],temp)
        return 'all assembly fixtures passed (exit status 0)'
    if language == 'cmd':
        return run([os.environ.get('COMSPEC','cmd.exe'),'/d','/c',str(path)],temp)
    if language == 'powershell':
        return run([tool('pwsh'),'-NoLogo','-NoProfile','-NonInteractive','-File',str(path)],temp)
    if language == 'go':
        run([tool('go'),'build','-o',str(binary),str(path)],temp)
        return run([str(binary)],temp)
    if language == 'php':
        run([tool('php'),'-l',str(path)],temp)
        return run([tool('php'),str(path)],temp)
    if language == 'bash':
        # Git Bash accepts forward-slash Windows paths.
        script_path = path.as_posix()
        run([tool('bash'),'-n',script_path],temp)
        return run([tool('bash'),script_path],temp)
    if language == 'ruby':
        run([tool('ruby'),'-c',str(path)],temp)
        return run([tool('ruby'),str(path)],temp)
    raise ValueError(language)

def main():
    global NIM_BACKEND
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--language',choices=LANGUAGES,action='append')
    parser.add_argument('--require-tools',action='store_true',help='Fail if any selected runtime is unavailable.')
    parser.add_argument('--report',type=Path,help='Save machine-readable validation results.')
    parser.add_argument('--nim-backend',choices=['c','js'],default='c',help='JS backend requires node instead of a C compiler.')
    args = parser.parse_args()
    NIM_BACKEND = args.nim_backend
    manifest = json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
    selected = set(args.language or LANGUAGES)
    report = {'platform':platform.platform(),'python':platform.python_version(),
              'sqlite':sqlite3.sqlite_version,'nim_backend':NIM_BACKEND,'files':[],'skipped_languages':{},'runtime_paths':{}}
    failures = 0
    started = time.monotonic()
    for language in LANGUAGES:
        if language not in selected:
            continue
        entries = [entry for entry in manifest if entry['language'] == language]
        for entry in entries:
            content = (ROOT/entry['path']).read_bytes()
            if hashlib.sha256(content).hexdigest() != entry['sha256']:
                raise AssertionError(f'manifest hash mismatch: {entry["path"]}')
        missing = [name for name in required(language) if not tool(name)]
        if language == 'nim' and NIM_BACKEND == 'js' and not tool('node'):
            missing.append('node')
        if language == 'assembly' and (platform.system() != 'Linux' or platform.machine().lower() not in ('x86_64','amd64')):
            missing.append('native Linux x86-64 host')
        if missing:
            report['skipped_languages'][language] = missing
            print(f'SKIP {language}: missing {", ".join(missing)}',flush=True)
            if args.require_tools:
                failures += 1
            continue
        report['runtime_paths'][language] = {name:tool(name) for name in required(language)}
        passed = 0
        with tempfile.TemporaryDirectory(prefix='sample-code-') as directory:
            for entry in entries:
                record = {'path':entry['path'],'fixtures':entry['fixtures']}
                try:
                    record['output'] = verify_file(entry,Path(directory))
                    record['status'] = 'passed'
                    passed += 1
                except Exception as error:
                    record['status'] = 'failed'
                    record['error'] = str(error)
                    failures += 1
                    print(f'FAIL {entry["path"]}: {error}',flush=True)
                report['files'].append(record)
        print(f'{language}: {passed}/{len(entries)} programs passed',flush=True)
    report['elapsed_seconds'] = round(time.monotonic()-started,2)
    report['failures'] = failures
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return 1 if failures else 0

if __name__ == '__main__':
    sys.exit(main())
