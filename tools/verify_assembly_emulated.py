#!/usr/bin/env python3
"""Check the x86-64 instruction paths on a non-Linux host.

Optional dependencies: pip install keystone-engine unicorn
NASM directives are removed; Keystone assembles the unchanged instruction lines.
Unicorn executes them with an emulated stack and intercepts Linux exit syscalls.
This checks machine-code behavior, not NASM syntax or native ELF loading. The
normal verifier on Linux additionally assembles with NASM and links with ld.
"""
import json
from pathlib import Path
import sys
from keystone import Ks, KS_ARCH_X86, KS_MODE_64
from unicorn import Uc, UC_ARCH_X86, UC_MODE_64, UC_HOOK_INSN
from unicorn.x86_const import UC_X86_REG_RSP, UC_X86_REG_RAX, UC_X86_REG_RDI, UC_X86_INS_SYSCALL

ROOT = Path(__file__).resolve().parents[1]

def verify(path):
    lines = []
    for original in path.read_text(encoding='utf-8').splitlines():
        line = original.split(';',1)[0].strip()
        if not line or line.startswith(('bits ','default ','global ','section ')):
            continue
        lines.append(line)
    code, count = Ks(KS_ARCH_X86,KS_MODE_64).asm('\n'.join(lines),addr=0x100000)
    emulator = Uc(UC_ARCH_X86,UC_MODE_64)
    emulator.mem_map(0x100000,0x10000)
    emulator.mem_write(0x100000,bytes(code))
    emulator.mem_map(0x200000,0x10000)
    emulator.reg_write(UC_X86_REG_RSP,0x20fff0)
    exit_codes = []
    def syscall(machine,_):
        if machine.reg_read(UC_X86_REG_RAX) != 60:
            raise AssertionError('Unexpected syscall')
        exit_codes.append(machine.reg_read(UC_X86_REG_RDI))
        machine.emu_stop()
    emulator.hook_add(UC_HOOK_INSN,syscall,None,1,0,UC_X86_INS_SYSCALL)
    emulator.emu_start(0x100000,0x100000+len(code),timeout=5000000,count=2000000)
    if exit_codes != [0]:
        raise AssertionError(f'Expected successful Linux exit; got {exit_codes}')
    return {'path':path.relative_to(ROOT).as_posix(),'status':'passed','machine_code_bytes':len(code),'assembled_statements':count}

def main():
    results = [verify(path) for path in sorted((ROOT/'assembly').glob('*.asm'))]
    print(json.dumps({'mode':'Keystone assembly + Unicorn x86-64 emulation','files':results},indent=2))
    return 0

if __name__ == '__main__':
    sys.exit(main())
