; Gcd.
; x86-64; NASM Intel syntax; Linux ELF64; System V integer argument registers
; Contract: a,b >= 0; gcd(0,0) is defined as 0.
; nasm -f elf64 FILE.asm -o demo.o && ld demo.o -o demo && ./demo
; RAX is the signed result. All scratch registers are caller-saved.
; Each fixture exits with its one-based index on failure; 0 means success.
bits 64
default rel
global _start
section .text
_start:
    mov rdi, 48
    mov rsi, 18
    call compute
    cmp rax, 6
    jne fail_1
    mov rdi, 0
    mov rsi, 7
    call compute
    cmp rax, 7
    jne fail_2
    mov rdi, 7
    mov rsi, 0
    call compute
    cmp rax, 7
    jne fail_3
    mov rdi, 0
    mov rsi, 0
    call compute
    cmp rax, 0
    jne fail_4
    mov rdi, 35
    mov rsi, 64
    call compute
    cmp rax, 1
    jne fail_5
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
fail_5:
    mov edi, 5
    mov eax, 60
    syscall

compute:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rdi
    mov [rbp-16], rsi
.branch_1:
    mov rax, [rbp-16]
    push rax
    mov rax, 0
    mov rcx, rax
    pop rax
    cmp rax, rcx
    je .branch_2
    mov rax, [rbp-8]
    push rax
    mov rax, [rbp-16]
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rax, rdx
    mov [rbp-24], rax
    mov rax, [rbp-16]
    mov [rbp-8], rax
    mov rax, [rbp-24]
    mov [rbp-16], rax
    jmp .branch_1
.branch_2:
    mov rax, [rbp-8]
    leave
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
