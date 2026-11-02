#!/usr/bin/env python3
"""Compile and run hand-authored advanced examples using installed tools.

python tools/verify_advanced.py --require-tools
python tools/verify_advanced.py --language nim --nim-backend js
On non-Linux hosts, --emulate-assembly needs NASM plus pip install unicorn.
All programs are self-contained and execute their own deterministic checks.
"""
import argparse
import json
import os
from pathlib import Path
import platform
import shutil
import sqlite3
import sys
import tempfile
import verify as base

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {'nim':'.nim','cmd':'.cmd','assembly':'.asm','powershell':'.ps1',
              'sql':'.sql','bash':'.sh','rust':'.rs','ruby':'.rb','go':'.go','php':'.php'}

SQL_REJECTIONS = {
    'double_entry_posting.sql': [
        'UPDATE line SET debit=debit+1 WHERE id=1',
        'DELETE FROM line WHERE id=1',
        'INSERT INTO line(journal_id,account_id,debit,credit) VALUES(1,1,1,0)',
        "UPDATE journal SET state='posted' WHERE id=3",
        'UPDATE line SET journal_id=1 WHERE id=5',
        "INSERT INTO journal(id,external_key,state) VALUES(99,'bypass','posted')",
    ],
    'bill_of_materials.sql': [
        'INSERT INTO component VALUES(2,1,1)',
        'UPDATE component SET child=1 WHERE parent=2 AND child=4',
        'INSERT INTO component VALUES(4,7,1)',
        'UPDATE part SET assembly=0 WHERE id=2',
    ],
}

def sql_rejections(connection,name):
    statements = SQL_REJECTIONS.get(name,[])
    for statement in statements:
        connection.execute('SAVEPOINT rejected_operation')
        try:
            try:
                connection.execute(statement)
            except sqlite3.IntegrityError:
                pass
            else:
                raise AssertionError('SQL accepted forbidden operation: '+statement)
        finally:
            connection.execute('ROLLBACK TO rejected_operation')
            connection.execute('RELEASE rejected_operation')
    return len(statements)

def emulate_assembly(path, temporary):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_64, UC_HOOK_INSN
    from unicorn.x86_const import UC_X86_REG_RSP, UC_X86_REG_RAX, UC_X86_REG_RDI, UC_X86_INS_SYSCALL
    image = temporary/'image.bin'
    base.run([shutil.which('nasm'),'-DFLAT','-f','bin',str(path),'-o',str(image)],temporary)
    code = image.read_bytes()
    machine = Uc(UC_ARCH_X86,UC_MODE_64)
    machine.mem_map(0x100000,0x100000)
    machine.mem_write(0x100000,code)
    machine.mem_map(0x300000,0x10000)
    machine.reg_write(UC_X86_REG_RSP,0x30fff0)
    exits = []
    def syscall(emu,_):
        if emu.reg_read(UC_X86_REG_RAX) != 60:
            raise AssertionError('unexpected system call')
        exits.append(emu.reg_read(UC_X86_REG_RDI))
        emu.emu_stop()
    machine.hook_add(UC_HOOK_INSN,syscall,None,1,0,UC_X86_INS_SYSCALL)
    machine.emu_start(0x100000,0x200000,timeout=10000000,count=10000000)
    if exits != [0]: raise AssertionError(f'assembly failed or timed out: {exits}')
    # Also ask NASM to accept the real ELF64 source, even on Windows.
    base.run([shutil.which('nasm'),'-f','elf64',str(path),'-o',str(temporary/'native.o')],temporary)
    return 'NASM flat-image execution under Unicorn + ELF64 assembly passed'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--language',action='append',choices=list(EXTENSIONS))
    parser.add_argument('--require-tools',action='store_true')
    parser.add_argument('--nim-backend',choices=['c','js'],default='c')
    parser.add_argument('--emulate-assembly',action='store_true')
    parser.add_argument('--report',type=Path)
    args = parser.parse_args()
    base.NIM_BACKEND = args.nim_backend
    records = []
    failures = 0
    for language in args.language or EXTENSIONS:
        paths = sorted((ROOT/'advanced'/language).glob('*'+EXTENSIONS[language]))
        needed = base.required(language)
        if language == 'assembly' and args.emulate_assembly: needed = ['nasm']
        missing = [name for name in needed if not shutil.which(name)]
        if language == 'nim' and args.nim_backend == 'js' and not shutil.which('node'): missing.append('node')
        if language == 'assembly' and not args.emulate_assembly and platform.system() != 'Linux': missing.append('Linux host')
        if missing:
            print(f'SKIP {language}: missing {missing}',flush=True)
            if args.require_tools: failures += 1
            continue
        with tempfile.TemporaryDirectory(prefix='advanced-code-') as directory:
            for path in paths:
                relative = path.relative_to(ROOT).as_posix()
                try:
                    if language == 'sql':
                        with sqlite3.connect(':memory:') as connection:
                            connection.executescript(path.read_text(encoding='utf-8'))
                            count = connection.execute('SELECT COUNT(*) FROM checks').fetchone()[0]
                            if count < 1: raise AssertionError('no result checks')
                            if connection.execute('PRAGMA integrity_check').fetchone()[0] != 'ok': raise AssertionError('integrity failure')
                            if connection.execute('PRAGMA foreign_key_check').fetchall(): raise AssertionError('foreign key failure')
                            rejected = sql_rejections(connection,path.name)
                        output = f'{count} SQL result checks and {rejected} expected-rejection checks passed'
                    elif language == 'assembly' and args.emulate_assembly:
                        output = emulate_assembly(path,Path(directory))
                    else:
                        output = base.verify_file({'language':language,'path':relative,'fixtures':1},Path(directory))
                        if not output and language != 'assembly':
                            raise AssertionError('program did not print its success marker')
                    records.append({'path':relative,'status':'passed','output':output})
                    print('PASS '+relative+': '+output,flush=True)
                except Exception as error:
                    failures += 1
                    records.append({'path':relative,'status':'failed','error':str(error)})
                    print('FAIL '+relative+': '+str(error),flush=True)
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps({'failures':failures,'files':records},indent=2)+'\n',encoding='utf-8')
    return int(failures > 0)

if __name__ == '__main__':
    sys.exit(main())
