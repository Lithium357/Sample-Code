; Strict signed decimal-to-int64 parser with overflow checks before arithmetic.
; NASM / Linux x86-64 / System V. No whitespace or separators; optional +/-.
; nasm -f elf64 parse_int64.asm -o parse.o && ld parse.o -o parse && ./parse
; Flat emulation: nasm -DFLAT -f bin parse_int64.asm -o parse.bin
bits 64
default rel
%ifdef FLAT
org 0x100000
%else
global _start
%endif
section .text
_start:
    lea r12, [rel tests]
    mov r13d, (tests_end-tests)/32
.next:
    mov rdi, [r12]
    mov rsi, [r12+8]
    call parse_i64
    cmp rcx, [r12+24]
    jne fail
    cmp rax, [r12+16]
    jne fail
    add r12, 32
    dec r13
    jnz .next
    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, 1
    mov eax, 60
    syscall

; parse_i64(bytes=RDI,length=RSI): RAX=value, RCX=status (0/1/2).
; 1 means syntax error, 2 means overflow. Errors return value 0.
; Negative accumulation can represent INT64_MIN, unlike positive accumulation
; followed by negation. All memory accesses are bounded by the supplied length.
parse_i64:
    xor eax, eax
    xor r8d, r8d
    test rsi, rsi
    jz .syntax
    movzx edx, byte [rdi]
    cmp edx, '-'
    jne .plus
    mov r8d, 1
    jmp .sign
.plus:
    cmp edx, '+'
    jne .digits
.sign:
    inc rdi
    dec rsi
    jz .syntax
.digits:
    mov r10, -922337203685477580
    mov r9d, 7
    add r9, r8
.loop:
    movzx edx, byte [rdi]
    sub edx, '0'
    cmp edx, 9
    ja .syntax
    cmp rax, r10
    jl .overflow
    jne .accumulate
    cmp rdx, r9
    ja .overflow
.accumulate:
    imul rax, rax, 10
    sub rax, rdx
    inc rdi
    dec rsi
    jnz .loop
    test r8, r8
    jnz .success
    neg rax
.success:
    xor ecx, ecx
    ret
.syntax:
    xor eax, eax
    mov ecx, 1
    ret
.overflow:
    xor eax, eax
    mov ecx, 2
    ret

section .data align=16
zero: db '0'
negative_zero: db '-0000'
positive: db '+12345'
negative: db '-12345'
maximum: db '9223372036854775807'
minimum: db '-9223372036854775808'
too_positive: db '9223372036854775808'
too_negative: db '-9223372036854775809'
many: db '999999999999999999999999999999'
only_sign: db '-'
space: db ' 1'
suffix: db '12x'
double_sign: db '+-1'
embedded_zero: db '1',0,'2'
leading_zeros: db '00000000000000000000000000000000000042'
tests:
    dq 0,0,0,1
    dq zero,1,0,0
    dq negative_zero,5,0,0
    dq positive,6,12345,0
    dq negative,6,-12345,0
    dq maximum,19,9223372036854775807,0
    dq minimum,20,-9223372036854775808,0
    dq too_positive,19,0,2
    dq too_negative,20,0,2
    dq many,30,0,2
    dq only_sign,1,0,1
    dq space,2,0,1
    dq suffix,3,0,1
    dq double_sign,3,0,1
    dq embedded_zero,3,0,1
    dq leading_zeros,38,42,0
tests_end:
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
