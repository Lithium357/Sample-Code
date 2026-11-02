; Integer log.
; x86-64; NASM Intel syntax; Linux ELF64; System V integer argument registers
; Contract: n >= 1; base >= 2; returns floor(log_base(n)).
; nasm -f elf64 FILE.asm -o demo.o && ld demo.o -o demo && ./demo
; RAX is the signed result. All scratch registers are caller-saved.
; Each fixture exits with its one-based index on failure; 0 means success.
bits 64
default rel
global _start
section .text
_start:
    mov rdi, 1
    mov rsi, 2
    call compute
    cmp rax, 0
    jne fail_1
    mov rdi, 8
    mov rsi, 2
    call compute
    cmp rax, 3
    jne fail_2
    mov rdi, 99
    mov rsi, 10
    call compute
    cmp rax, 1
    jne fail_3
    mov rdi, 100
    mov rsi, 10
    call compute
    cmp rax, 2
    jne fail_4
    xor edi, edi
    mov eax, 60
    syscall
fail_1:
    mov edi, 1
    mov eax, 60
    syscall
fail_2:
    mov edi, 2
    mov eax, 60
    syscall
fail_3:
    mov edi, 3
    mov eax, 60
    syscall
fail_4:
    mov edi, 4
    mov eax, 60
    syscall

compute:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rax, 0
    mov [rbp-24], rax
.branch_1:
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rcx, rax
    pop rax
    cmp rax, rcx
    jl .branch_2
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov [rbp-8], rax
    mov rax, [rbp-24]
    push rax
    mov rax, 1
    mov rcx, rax
    pop rax
    add rax, rcx
    mov [rbp-24], rax
    jmp .branch_1
.branch_2:
    mov rax, [rbp-24]
    leave
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
