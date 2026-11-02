; Triangular index.
; x86-64; NASM Intel syntax; Linux ELF64; System V integer argument registers
; Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
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
    mov rdi, 1
    call compute
    cmp rax, 1
    jne fail_2
    mov rdi, 15
    call compute
    cmp rax, 5
    jne fail_3
    mov rdi, 14
    call compute
    cmp rax, -1
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
    mov rax, 0
    mov [rbp-24], rax
    mov rax, 0
    mov [rbp-16], rax
.branch_1:
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    mov rcx, rax
    pop rax
    cmp rax, rcx
    jge .branch_2
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rcx, rax
    pop rax
    add rax, rcx
    mov [rbp-16], rax
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-16]
    mov rcx, rax
    pop rax
    add rax, rcx
    mov [rbp-24], rax
    jmp .branch_1
.branch_2:
    mov rax, [rbp-24]
    push rax
    mov rax, [rbp-8]
    mov rcx, rax
    pop rax
    cmp rax, rcx
    jne .branch_3
    mov rax, [rbp-16]
    leave
    ret
    jmp .branch_4
.branch_3:
.branch_4:
    mov rax, 1
    neg rax
    leave
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
