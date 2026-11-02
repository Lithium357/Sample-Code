; Greedy coin count.
; x86-64; NASM Intel syntax; Linux ELF64; System V integer argument registers
; Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
; nasm -f elf64 FILE.asm -o demo.o && ld demo.o -o demo && ./demo
; RAX is the signed result. All scratch registers are caller-saved.
; Each fixture exits with its one-based index on failure; 0 means success.
bits 64
default rel
global _start
section .text
_start:
    mov rdi, 0
    call compute
    cmp rax, 0
    jne fail_1
    mov rdi, 30
    call compute
    cmp rax, 2
    jne fail_2
    mov rdi, 41
    call compute
    cmp rax, 4
    jne fail_3
    mov rdi, 99
    call compute
    cmp rax, 9
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
    sub rsp, 16
    mov [rbp-8], rdi
    mov rax, [rbp-8]
    push rax
    mov rax, 25
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 25
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rax, rdx
    mov [rbp-8], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rcx, rax
    pop rax
    add rax, rcx
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 10
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rax, rdx
    mov [rbp-8], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rcx, rax
    pop rax
    add rax, rcx
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 5
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rax, rdx
    mov [rbp-8], rax
    mov rax, [rbp-16]
    push rax
    mov rax, [rbp-8]
    mov rcx, rax
    pop rax
    add rax, rcx
    leave
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
