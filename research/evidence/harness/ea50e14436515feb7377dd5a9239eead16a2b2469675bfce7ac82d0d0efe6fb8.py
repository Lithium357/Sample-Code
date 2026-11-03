"""Bounded-access/ABI fixtures for the related ULEB32 functions; control only."""


def encode_reference(value):
    result = bytearray()
    while True:
        value, digit = divmod(value, 128)
        result.append(digit + (128 if value else 0))
        if not value:
            return bytes(result)


def reference(data, available):
    value = 0
    for index in range(min(available, 5)):
        byte = data[index]
        if index == 4 and byte > 15:
            return 2, None, index + 1
        value += (byte % 128) * (128 ** index)
        if byte < 128:
            prefix = data[:index + 1]
            if prefix != encode_reference(value):
                return 3, None, index + 1
            return 0, value.to_bytes(4, 'little') + len(prefix).to_bytes(4, 'little'), index + 1
    return 1, None, min(available, 5)


def vectors():
    result = []
    values = list(range(256)) + [16383, 16384, 2097151, 2097152, 268435455,
                               268435456, 2147483647, 2147483648, 4294967295]
    values += [(i * 2654435761) % (2 ** 32) for i in range(64)]
    for value in values:
        encoded = encode_reference(value)
        result.append((encoded + b'\xff\x00', len(encoded) + 2, 'separate'))
        for prefix in range(len(encoded)):
            result.append((encoded[:prefix], prefix, 'separate'))
    for data in [b'\x80\x00', b'\x81\x00', b'\x80\x80\x00', b'\xff' * 5,
                 b'\x80' * 5, b'\xff\xff\xff\xff\x10', b'\x80\x80\x80\x80\x00']:
        result.append((data, len(data), 'separate'))
        result.append((data, len(data), 'null_output'))
    result += [(b'', 0, 'null_output')]
    for value in [0, 127, 128, 16384, 2147483648, 4294967295]:
        data = encode_reference(value)
        for available in [1 << 63, (1 << 64) - 1]:
            result.append((data, available, 'separate'))
        for alias in ['same', 'before', 'after']:
            result.append((data, len(data), alias))
    return list(dict.fromkeys(result))


def validate_image(image, isa, negative_controls=True):
    from unicorn import Uc, UC_ARCH_X86, UC_MODE_64, UC_ARCH_RISCV, UC_MODE_RISCV64
    from unicorn import UC_HOOK_MEM_READ, UC_HOOK_MEM_WRITE, UC_MEM_READ, UC_MEM_WRITE
    from unicorn import x86_const as x86, riscv_const as rv
    if isa == 'x86_64':
        architecture, mode = UC_ARCH_X86, UC_MODE_64
        arguments = [x86.UC_X86_REG_RDI, x86.UC_X86_REG_RSI, x86.UC_X86_REG_RDX]
        saved = [getattr(x86, 'UC_X86_REG_' + name) for name in ['RBX', 'RBP', 'R12', 'R13', 'R14', 'R15']]
        stack, pc, status = x86.UC_X86_REG_RSP, x86.UC_X86_REG_RIP, x86.UC_X86_REG_RAX
    elif isa == 'riscv64':
        assert image and len(image) % 4 == 0
        assert all(int.from_bytes(image[i:i+4], 'little') & 3 == 3 for i in range(0, len(image), 4)), 'not RV64I instructions'
        architecture, mode = UC_ARCH_RISCV, UC_MODE_RISCV64
        arguments = [rv.UC_RISCV_REG_A0, rv.UC_RISCV_REG_A1, rv.UC_RISCV_REG_A2]
        saved = [getattr(rv, 'UC_RISCV_REG_X' + str(i)) for i in [3, 4, 8, 9, *range(18, 28)]]
        stack, pc, status = rv.UC_RISCV_REG_SP, rv.UC_RISCV_REG_PC, rv.UC_RISCV_REG_A0
    else:
        raise ValueError('unsupported ISA')
    cases = vectors()
    for data, available, alias in cases:
        expected_status, expected_bytes, read_count = reference(data, available)
        assert len(data) >= read_count
        machine = Uc(architecture, mode)
        machine.mem_map(0x100000, 0x2000)
        machine.mem_write(0x100000, image)
        for base in (0x200000, 0x300000, 0x400000):
            machine.mem_map(base, 0x1000)
            machine.mem_write(base, b'\xa5' * 0x1000)
        source = 0x200100 if available else 0
        output = 0x300019
        if alias == 'null_output':
            assert expected_status != 0
            output = 0
        elif alias == 'same': output = source
        elif alias == 'before': output = source - 3
        elif alias == 'after': output = source + 1
        if data: machine.mem_write(source, data)
        before = {base: bytes(machine.mem_read(base, 0x1000)) for base in (0x200000, 0x300000)}
        for reg, value in zip(arguments, [source, available, output]): machine.reg_write(reg, value)
        for index, reg in enumerate(saved): machine.reg_write(reg, 0x5566778800000000 + index)
        initial_stack = 0x400fe8 if isa == 'x86_64' else 0x400ff0
        machine.reg_write(stack, initial_stack)
        if isa == 'x86_64':
            machine.mem_write(initial_stack, (0x100f00).to_bytes(8, 'little'))
            machine.reg_write(x86.UC_X86_REG_EFLAGS, 2) # DF clear, as required on entry
        else:
            machine.reg_write(rv.UC_RISCV_REG_RA, 0x100f00)
        def memory(emu, access, address, size, value, user):
            if 0x400000 <= address and address + size <= 0x401000: return
            if access == UC_MEM_READ:
                assert source and source <= address and address + size <= source + read_count, 'read beyond required input prefix'
            elif access == UC_MEM_WRITE:
                assert expected_status == 0 and output <= address and address + size <= output + 8, 'write on failure or beyond output'
        machine.hook_add(UC_HOOK_MEM_READ | UC_HOOK_MEM_WRITE, memory)
        machine.emu_start(0x100000, 0x100f00, timeout=1000000, count=1000)
        assert machine.reg_read(pc) == 0x100f00, 'did not return within instruction budget'
        assert machine.reg_read(status) == expected_status, 'wrong status'
        expected_stack = initial_stack + (8 if isa == 'x86_64' else 0)
        assert machine.reg_read(stack) == expected_stack, 'stack not restored'
        for index, reg in enumerate(saved):
            assert machine.reg_read(reg) == 0x5566778800000000 + index, 'preserved register changed'
        if isa == 'x86_64': assert machine.reg_read(x86.UC_X86_REG_EFLAGS) & 0x400 == 0, 'DF set on return'
        for base, initial in before.items():
            expected = bytearray(initial)
            if expected_status == 0 and base <= output < base + 0x1000:
                expected[output-base:output-base+8] = expected_bytes
            assert bytes(machine.mem_read(base, 0x1000)) == bytes(expected), 'wrong value/count, source mutation or guard corruption'
    controls = []
    if negative_controls:
        if isa == 'x86_64':
            mutations = [('clobber rbx', b'\x31\xdb' + image, 'preserved register'),
                         ('return success without decoding', b'\x31\xc0\xc3' + image, 'wrong status')]
        else:
            mutations = [('clobber s0', (0x00000413).to_bytes(4, 'little') + image, 'preserved register'),
                         ('return success without decoding', bytes.fromhex('1305000067800000') + image, 'wrong status')]
            words = [int.from_bytes(image[i:i+4], 'little') for i in range(0, len(image), 4)]
            branches = [i for i, word in enumerate(words) if word & 0x7f == 0x63
                        and (word >> 12) & 7 == 7 and (word >> 15) & 31 == 5 and (word >> 20) & 31 == 11]
            assert len(branches) == 1, 'expected one unsigned size bound branch'
            mutant = bytearray(image); i = branches[0]
            mutant[i*4:i*4+4] = (words[i] ^ (2 << 12)).to_bytes(4, 'little')
            mutations.append(('signed available comparison', bytes(mutant), 'wrong status'))
        for name, code, expected in mutations:
            reason = None
            try: validate_image(code, isa, False)
            except AssertionError as error: reason = str(error)
            assert reason and expected in reason, 'negative control did not fail for intended reason: ' + name
            controls.append({'mutation': name, 'detected_by': reason})
    return {'vectors': len(cases), 'isa': isa, 'negative_controls': controls,
            'scope': 'Function-body emulation: division-based canonical reference, every required input access, failure nonwrites, unaligned output, aliases, unsigned large sizes, source/guards, preserved registers, stack and DF where applicable.',
            'limitations': 'Not a native hardware/ELF-loader or operating-system test. Native NASM fixture is a separate execution mode.'}
