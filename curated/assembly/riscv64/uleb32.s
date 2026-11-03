# ISA: RV64I little endian, GNU syntax, LP64 integer calling convention.
# a0=source, a1=unsigned available size, a2=output; a0 returns status:
# 0 success, 1 truncated, 2 overflow, 3 noncanonical (redundant last zero).
# Success writes u32 LE value + u32 LE consumed length. Failure writes nothing.
# Input/output may overlap; all input reads precede stores. Output may be
# unaligned because each store is a byte. Source is readable through an early
# terminator or min(available,5) bytes; output is writable for eight on success.
# NULL source with zero available is allowed. Only the first encoding is inspected.
# No OS calls, compressed instructions, relaxation or native-hardware claim.
# riscv64-linux-gnu-as -march=rv64i -mabi=lp64 uleb32.s -o decode.o
# riscv64-linux-gnu-ld -m elf64lriscv --no-relax -Ttext=0x100000 -e decode_uleb32 decode.o -o decode.elf
# The repository harness extracts linked .text and runs it under Unicorn.
.option norvc
.option norelax
.text
.align 2
.globl decode_uleb32
.type decode_uleb32, @function
decode_uleb32:
    li t0, 0                       # input index
    li t1, 0                       # value accumulator
    li t2, 0                       # bit position
decode_loop:
    bgeu t0, a1, decode_truncated  # size_t must be compared unsigned
    add t5, a0, t0
    lbu t3, 0(t5)                  # zero extension matters for bytes >= 128
    li t4, 4
    bne t0, t4, decode_accumulate
    li t4, 15
    bltu t4, t3, decode_overflow
decode_accumulate:
    andi t4, t3, 127
    sll t4, t4, t2
    or t1, t1, t4
    andi t4, t3, 128
    bnez t4, decode_more
    beqz t0, decode_success
    andi t4, t3, 127
    beqz t4, decode_noncanonical
decode_success:
    sb t1, 0(a2)
    srli t1, t1, 8
    sb t1, 1(a2)
    srli t1, t1, 8
    sb t1, 2(a2)
    srli t1, t1, 8
    sb t1, 3(a2)
    addi t0, t0, 1
    sb t0, 4(a2)
    sb zero, 5(a2)
    sb zero, 6(a2)
    sb zero, 7(a2)
    li a0, 0
    ret
decode_more:
    addi t0, t0, 1
    addi t2, t2, 7
    j decode_loop
decode_truncated:
    li a0, 1
    ret
decode_overflow:
    li a0, 2
    ret
decode_noncanonical:
    li a0, 3
    ret
.size decode_uleb32, .-decode_uleb32
