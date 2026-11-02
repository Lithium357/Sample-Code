; NASM x86-64 Linux: overlap-safe memmove with System V return convention.
; nasm -f elf64 overlap_memmove.asm -o move.o && ld move.o -o move && ./move
; Optional flat emulator image: nasm -DFLAT -f bin ...
; 4352 cases compare every overlapping direction with an immutable byte oracle.
bits 64
default rel
%ifdef FLAT
org 0x100000
%else
global _start
%endif
section .text
_start:
    xor r12d,r12d ; destination offset
.destination:
    xor r13d,r13d ; source offset
.source:
    xor r14d,r14d ; length
.length:
    lea rdi,[rel actual]
    lea rsi,[rel expected]
    xor ecx,ecx
.initialize:
    mov [rdi+rcx],cl
    mov [rsi+rcx],cl
    inc ecx
    cmp ecx,32
    jb .initialize
    xor ecx,ecx
.oracle:
    cmp rcx,r14
    jae .copy
    lea rax,[r13+rcx]
    lea rdx,[r12+rcx]
    mov [rsi+rdx],al
    inc rcx
    jmp .oracle
.copy:
    lea rdi,[rel actual]
    add rdi,r12
    lea rsi,[rel actual]
    add rsi,r13
    mov rdx,r14
    mov r15,rdi
    call move_bytes
    cmp rax,r15
    jne fail
    pushfq
    pop rax
    test eax,0x400 ; ABI requires DF clear on return.
    jnz fail
    lea rdi,[rel actual]
    lea rsi,[rel expected]
    mov ecx,32
    repe cmpsb
    jne fail
    inc r14
    cmp r14,16
    jbe .length
    inc r13
    cmp r13,16
    jb .source
    inc r12
    cmp r12,16
    jb .destination
    ; Zero length is valid even with null pointers.
    xor edi,edi
    xor esi,esi
    xor edx,edx
    call move_bytes
    test rax,rax
    jnz fail
    xor edi,edi
    mov eax,60
    syscall
fail:
    mov edi,1
    mov eax,60
    syscall

; move_bytes(destination=RDI,source=RSI,length=RDX) -> original destination RAX.
; Ranges must be valid and pointer+length must not wrap the address space.
move_bytes:
    mov rax,rdi
    mov rcx,rdx
    test rcx,rcx
    jz .empty
    cmp rdi,rsi
    jbe .forward
    lea r8,[rsi+rdx]
    cmp rdi,r8
    jae .forward
    lea rdi,[rdi+rdx-1]
    lea rsi,[rsi+rdx-1]
    std
    rep movsb
    cld
    ret
.forward:
    cld
    rep movsb
.empty:
    cld
    ret
section .data align=16
actual: times 32 db 0
expected: times 32 db 0
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
