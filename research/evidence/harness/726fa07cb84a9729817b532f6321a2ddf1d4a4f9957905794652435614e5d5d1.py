"""Execute marked ARM function bodies; not a native GNU/ELF portability test."""
from pathlib import Path

def validate_isa(path:Path,isa:str):
    from keystone import Ks, KS_ARCH_ARM64, KS_ARCH_ARM, KS_MODE_LITTLE_ENDIAN, KS_MODE_ARM
    from unicorn import Uc, UC_ARCH_ARM64, UC_ARCH_ARM, UC_MODE_ARM, UC_MODE_LITTLE_ENDIAN
    from unicorn import UC_HOOK_MEM_READ,UC_HOOK_MEM_WRITE,UC_MEM_READ,UC_MEM_WRITE
    from unicorn import arm64_const as a64,arm_const as arm
    source=path.read_text(encoding='utf-8')
    body=source.split('BEGIN FUNCTION',1)[1].split('END FUNCTION',1)[0]
    instructions='\n'.join(line.split('//')[0].split('@')[0].strip() for line in body.splitlines())
    if isa=='aarch64':
        assembler=Ks(KS_ARCH_ARM64,KS_MODE_LITTLE_ENDIAN)
        architecture,mode=UC_ARCH_ARM64,UC_MODE_LITTLE_ENDIAN
        arguments=[a64.UC_ARM64_REG_X0,a64.UC_ARM64_REG_X1,a64.UC_ARM64_REG_X2,a64.UC_ARM64_REG_X3]
        saved=[getattr(a64,'UC_ARM64_REG_X'+str(i)) for i in range(19,30)]
        stack,link=a64.UC_ARM64_REG_SP,a64.UC_ARM64_REG_LR
        pc=a64.UC_ARM64_REG_PC
    elif isa=='armv7':
        assembler=Ks(KS_ARCH_ARM,KS_MODE_ARM|KS_MODE_LITTLE_ENDIAN)
        architecture,mode=UC_ARCH_ARM,UC_MODE_ARM|UC_MODE_LITTLE_ENDIAN
        arguments=[arm.UC_ARM_REG_R0,arm.UC_ARM_REG_R1,arm.UC_ARM_REG_R2,arm.UC_ARM_REG_R3]
        saved=[getattr(arm,'UC_ARM_REG_R'+str(i)) for i in range(4,12)]
        stack,link=arm.UC_ARM_REG_SP,arm.UC_ARM_REG_LR
        pc=arm.UC_ARM_REG_PC
    else:raise ValueError('unsupported emulation ISA')
    encoded,_=assembler.asm(instructions,addr=0x100000)
    vectors=[(b'',0,0),(b'aZz!\x00\x80',6,3),(b'aZz!\x00\x80',6,12),(bytes(range(256)),256,256)]
    for length in range(20):
        for capacity in range(20):
            vectors.append((bytes((i*37+89)%256 for i in range(length)),length,capacity))
    for data,length,capacity in vectors:
        copied=min(length,capacity)
        machine=Uc(architecture,mode)
        for base in (0x100000,0x200000,0x300000,0x400000):machine.mem_map(base,0x1000)
        machine.mem_write(0x100000,bytes(encoded))
        source_address=0x200010 if copied else 0
        target_address=0x300010 if copied else 0
        if data:machine.mem_write(0x200010,data)
        initial=bytes([0xa5])*512
        machine.mem_write(0x300000,initial)
        machine.reg_write(stack,0x400ff0)
        machine.reg_write(link,0x100800)
        for i,register in enumerate(saved):machine.reg_write(register,0x5500+i)
        for register,value in zip(arguments,[target_address,source_address,length,capacity]):machine.reg_write(register,value)
        def memory(emu,access,address,size,value,user):
            if 0x400000<=address and address+size<=0x401000:return # Valid stack accesses.
            if access==UC_MEM_READ:
                if not source_address<=address or address+size>source_address+copied:
                    raise AssertionError('read outside copied source prefix')
            elif access==UC_MEM_WRITE:
                if not target_address<=address or address+size>target_address+copied:
                    raise AssertionError('write outside destination capacity')
        machine.hook_add(UC_HOOK_MEM_READ|UC_HOOK_MEM_WRITE,memory)
        machine.emu_start(0x100000,0x100800,timeout=1000000,count=10000)
        assert machine.reg_read(pc)==0x100800,'function did not return before instruction/time limit'
        assert machine.reg_read(arguments[0])==copied,'wrong return count'
        for i,register in enumerate(saved):assert machine.reg_read(register)==0x5500+i,'callee-saved register changed'
        assert machine.reg_read(stack)==0x400ff0,'stack not preserved'
        expected=bytearray(initial)
        expected[16:16+copied]=bytes(byte-32 if 97<=byte<=122 else byte for byte in data[:copied])
        assert bytes(machine.mem_read(0x300000,512))==bytes(expected),'wrong data or modified canary'
    return {'vectors':len(vectors),'isa':isa,'coverage':'marked function body assembled and executed; memory bounds, callee-saved registers, stack and canaries checked',
            'limitations':'GNU directives, native ELF linking, native OS execution and timing are not validated'}
