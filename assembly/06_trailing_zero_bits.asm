; Trailing zero bits.
; x86-64; NASM Intel syntax; Linux ELF64; System V integer argument registers
; Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
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
    cmp rax, -1
    jne fail_1
    mov rdi, 1
    call compute
    cmp rax, 0
    jne fail_2
    mov rdi, 40
    call compute
    cmp rax, 3
    jne fail_3
    mov rdi, 64
    call compute
    cmp rax, 6
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
    mov rax, 0
    mov rcx, rax
    pop rax
    cmp rax, rcx
    jne .branch_1
    mov rax, 1
    neg rax
    leave
    ret
    jmp .branch_2
.branch_1:
.branch_2:
    mov rax, 0
    mov [rbp-16], rax
.branch_3:
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov rax, rdx
    push rax
    mov rax, 0
    mov rcx, rax
    pop rax
    cmp rax, rcx
    jne .branch_4
    mov rax, [rbp-16]
    push rax
    mov rax, 1
    mov rcx, rax
    pop rax
    add rax, rcx
    mov [rbp-16], rax
    mov rax, [rbp-8]
    push rax
    mov rax, 2
    mov rcx, rax
    pop rax
    cqo
    idiv rcx
    mov [rbp-8], rax
    jmp .branch_3
.branch_4:
    mov rax, [rbp-16]
    leave
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
