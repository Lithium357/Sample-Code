"""Excluded control material: execute A64 bodies, never claim native hardware."""
import hashlib
import json
from pathlib import Path

BASE, CALLBACK, RETURN = 0x100000, 0x100e00, 0x100f00

def marked(source):
    body=source.split('// BEGIN FUNCTION',1)[1].split('// END FUNCTION',1)[0]
    return '\n'.join(line.split('//')[0].strip() for line in body.splitlines())

def assemble(body):
    from keystone import Ks,KS_ARCH_ARM64,KS_MODE_LITTLE_ENDIAN
    assembler=Ks(KS_ARCH_ARM64,KS_MODE_LITTLE_ENDIAN)
    image=bytes(assembler.asm(body,addr=BASE)[0])
    prefix=body.split('visit_s24le:',1)[0]
    offset=len(assembler.asm(prefix,addr=BASE)[0])
    assert image and len(image)<0x800 and len(image)%4==0
    return image,offset

def vectors(fixtures):
    cases=[]
    for row in fixtures:
        raw=bytes.fromhex(row['hex'])
        expected=[int.from_bytes(raw[i:i+3],'little',signed=True) for i in range(0,len(raw),3)]
        assert expected==row['signed'],'literal packed fixture disagrees with independent reference'
        cases.append((raw,len(expected),len(raw),0,None,1))
    for count in range(33):
        raw=bytes((i*137+count*29+17)%256 for i in range(3*count))
        for alignment in range(4):
            for available in sorted({0,max(0,len(raw)-1),len(raw),len(raw)+11,(1<<64)-1}):
                cases.append((raw,count,available,alignment,None,1))
        if count:
            for stop in sorted({0,count//2,count-1}):
                for value in (1,1<<32,1<<63):
                    cases.append((raw,count,len(raw),1,stop,value))
    for count in (33,34,1<<63,(1<<64)-1):
        for available in (0,96,(1<<64)-1):cases.append((b'',count,available,0,None,1))
    return cases

def execute_image(image,visitor_offset,cases):
    from unicorn import Uc,UcError,UC_ARCH_ARM64,UC_MODE_LITTLE_ENDIAN,UC_HOOK_MEM_READ,UC_HOOK_MEM_WRITE,UC_HOOK_MEM_INVALID,UC_HOOK_CODE,UC_MEM_READ
    from unicorn import arm64_const as a
    reg=lambda n:getattr(a,'UC_ARM64_REG_X'+str(n))
    mask=(1<<64)-1
    performed=0
    for raw,count,available,alignment,stop,stop_value in cases:
        for visitor in (False,True):
            status=2 if count>32 else 1 if available<3*count else 3 if visitor and stop is not None else 0
            used=0 if status in (1,2) else 3*(stop+1 if visitor and stop is not None else count)
            values=[int.from_bytes(raw[i:i+3],'little',signed=True) for i in range(0,used,3)]
            assert len(raw)>=used
            machine=Uc(UC_ARCH_ARM64,UC_MODE_LITTLE_ENDIAN)
            for address in (BASE,0x200000,0x300000,0x400000):machine.mem_map(address,0x1000)
            machine.mem_write(BASE,image)
            machine.mem_write(CALLBACK,b'\xc0\x03\x5f\xd6') # actual A64 ret
            source=0x200080+alignment if used else 0
            target=0x300040 if used else 0
            if raw:machine.mem_write(0x200080+alignment,raw)
            destination=bytes([0xa5])*512
            machine.mem_write(0x300000,destination)
            stack=bytes([0x5d])*4096
            machine.mem_write(0x400000,stack)
            machine.reg_write(a.UC_ARM64_REG_SP,0x401000)
            machine.reg_write(a.UC_ARM64_REG_LR,RETURN)
            for n in range(18,30):machine.reg_write(reg(n),0xa155000000000000+n)
            for n in range(8,16):machine.reg_write(getattr(a,'UC_ARM64_REG_Q'+str(n)),0x799000+n)
            context=0xabc012345678 # opaque; callback must receive it, not dereference
            arguments=[source,available,count,CALLBACK if used else 0,context] if visitor else [source,available,target,count]
            for n,value in enumerate(arguments):machine.reg_write(reg(n),value)
            calls=[]
            def memory(emu,access,address,size,value,user):
                if 0x400000<=address<0x401000:
                    assert visitor and 0x400fc0<=address and address+size<=0x401000,'stack access outside owned frame'
                elif access==UC_MEM_READ:
                    assert used and source<=address and address+size<=source+used,'source read outside consumed prefix'
                else:
                    assert not visitor and used and target<=address and address+size<=target+4*count,'output write outside valid range'
            violations=[]
            def invalid(emu,access,address,size,value,user):
                violations.append({'access':access,'address':address,'size':size})
                return False
            def callback(emu,address,size,user):
                if address!=CALLBACK:return
                assert visitor,'unexpected callback'
                index=len(calls)
                assert index<len(values),'extra callback'
                assert emu.reg_read(a.UC_ARM64_REG_SP)%16==0,'callback stack alignment'
                assert emu.reg_read(reg(0))==context,'callback context'
                assert emu.reg_read(reg(1))==values[index]&mask,'callback signed value'
                assert emu.reg_read(reg(2))==index,'callback index'
                calls.append(index)
                # A hostile-but-conforming callee destroys all x0..x17, then
                # sets its result. The ret stub consumes the incoming LR.
                for n in range(18):emu.reg_write(reg(n),0xdead000000+n)
                for n in [*range(8),*range(16,32)]:emu.reg_write(getattr(a,'UC_ARM64_REG_Q'+str(n)),0x55+n)
                emu.reg_write(reg(0),stop_value if stop==index else 0)
            machine.hook_add(UC_HOOK_MEM_READ|UC_HOOK_MEM_WRITE,memory)
            machine.hook_add(UC_HOOK_MEM_INVALID,invalid)
            machine.hook_add(UC_HOOK_CODE,callback)
            try:machine.emu_start(BASE+visitor_offset if visitor else BASE,RETURN,timeout=1000000,count=20000)
            except UcError as error:
                where=f'visitor={visitor}, count={count}, available={available}, pc={machine.reg_read(a.UC_ARM64_REG_PC):x}'
                if violations:raise AssertionError('unmapped access '+str(violations)+' '+where+' '+str(error)) from error
                raise AssertionError('Unicorn execution failure '+where+' '+str(error)) from error
            assert machine.reg_read(a.UC_ARM64_REG_PC)==RETURN,'function failed to return within instruction bound'
            assert machine.reg_read(reg(0))==status,'wrong status'
            assert machine.reg_read(reg(1))==used,'wrong consumed count'
            assert len(calls)==(used//3 if visitor else 0),'wrong callback count'
            assert machine.reg_read(a.UC_ARM64_REG_SP)==0x401000,'stack not restored'
            for n in range(18,30):assert machine.reg_read(reg(n))==0xa155000000000000+n,'preserved general register changed'
            for n in range(8,16):assert machine.reg_read(getattr(a,'UC_ARM64_REG_Q'+str(n)))&mask==0x799000+n,'preserved SIMD low half changed'
            assert bytes(machine.mem_read(0x400000,4096-64))==stack[:-64],'stack canary changed'
            expected=bytearray(destination)
            if not visitor and status==0:
                expected[64:64+4*count]=b''.join(value.to_bytes(4,'little',signed=True) for value in values)
            assert bytes(machine.mem_read(0x300000,512))==expected,'wrong decoded word or output canary'
            if raw:assert bytes(machine.mem_read(0x200080+alignment,len(raw)))==raw,'source modified'
            performed+=1
    return performed

def validate(source,fixture_path,image=None,evidence_directory=None):
    body=marked(source)
    assembled,offset=assemble(body)
    if image is None:image=assembled
    else:assert image==assembled,'GNU linked text differs from marked Keystone body'
    cases=vectors(json.loads(Path(fixture_path).read_text(encoding='utf-8')))
    count=execute_image(image,offset,cases)
    mutations=[
        ('zero extend negative sample','sbfx w6, w6, #0, #24','ubfx w6, w6, #0, #24','wrong decoded word'),
        ('ignore high callback result bits','cbnz x0, visit_stopped','cbnz w0, visit_stopped','wrong status'),
        ('clobber preserved register','unpack_s24le:','unpack_s24le:\n mov x19, #0','preserved general register'),
        ('signed count guard','b.hi unpack_count','b.gt unpack_count','wrong status'),
        ('omit short source guard','b.lo unpack_short','nop','unmapped access')]
    controls=[]
    for label,before,after,reason in mutations:
        assert body.count(before)==1
        mutant=body.replace(before,after)
        code,entry=assemble(mutant)
        rejected=None
        try:execute_image(code,entry,cases)
        except AssertionError as error:rejected=str(error)
        assert rejected and reason in rejected,'mutation missed intended assertion: '+label+': '+str(rejected)
        payload=mutant.encode('utf-8');digest=hashlib.sha256(payload).hexdigest()
        if evidence_directory:
            target=Path(evidence_directory)/(digest+'.s')
            if not target.exists():target.write_bytes(payload)
        controls.append({'mutation':label,'source_sha256':digest,'rejection':rejected,'assembly_mode':'Keystone body, Unicorn execution; excluded control material'})
    return {'executed_cases':count,'fixture_inputs':len(cases),'entry_offset':offset,'image_sha256':hashlib.sha256(image).hexdigest(),
            'isa':'Armv8-A A64 little endian','abi':'AAPCS64 LP64, two uint64 result fields in x0/x1',
            'controls':controls,'scope':'Unicorn function execution and callback ABI instrumentation, not hardware/ELF loader/OS execution'}
