; Stable LSD radix sort for signed 32-bit values, NASM x86-64 Linux.
; nasm -f elf64 radix_sort_i32.asm -o radix.o && ld radix.o -o radix && ./radix
; Four byte passes; the final bucket byte is XORed with 0x80 to order negatives.
; Caller supplies a disjoint scratch array of at least n dwords. No allocation.
bits 64
default rel
%ifdef FLAT
org 0x100000
%else
global _start
%endif
section .text
_start:
    lea rdi,[rel values]
    lea rsi,[rel scratch]
    mov edx,16
    call radix_sort
    lea rdi,[rel values]
    lea rsi,[rel expected]
    mov ecx,16
    repe cmpsd
    jne fail
    xor edi,edi
    xor esi,esi
    xor edx,edx
    call radix_sort
    lea rdi,[rel single]
    lea rsi,[rel scratch]
    mov edx,1
    call radix_sort
    cmp dword [rel single],-123
    jne fail
    ; Idempotence also exercises buckets with large gaps.
    lea rdi,[rel values]
    lea rsi,[rel scratch]
    mov edx,16
    call radix_sort
    lea rdi,[rel values]
    lea rsi,[rel expected]
    mov ecx,16
    repe cmpsd
    jne fail
    xor edi,edi
    mov eax,60
    syscall
fail:
    mov edi,1
    mov eax,60
    syscall

; radix_sort(values=RDI,scratch=RSI,count=RDX). Callee-saved registers preserved.
; Buffer lengths and disjointness are caller preconditions; count*4 cannot wrap.
radix_sort:
    push r12
    push r13
    push r14
    push r15
    sub rsp,2048 ; 256 qword counters/start offsets
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    xor r15d,r15d
    cmp r14,2
    jb .done
.pass:
    mov rdi,rsp
    xor eax,eax
    mov ecx,256
    cld
    rep stosq
    xor r8d,r8d
.count:
    mov eax,[r12+r8*4]
    mov ecx,r15d
    shr eax,cl
    and eax,255
    cmp r15d,24
    jne .count_unsigned
    xor eax,128
.count_unsigned:
    inc qword [rsp+rax*8]
    inc r8
    cmp r8,r14
    jb .count
    xor r8d,r8d
    xor r9d,r9d
.prefix:
    mov r10,[rsp+r8*8]
    mov [rsp+r8*8],r9
    add r9,r10
    inc r8
    cmp r8,256
    jb .prefix
    xor r8d,r8d
.scatter:
    mov r11d,[r12+r8*4]
    mov eax,r11d
    mov ecx,r15d
    shr eax,cl
    and eax,255
    cmp r15d,24
    jne .scatter_unsigned
    xor eax,128
.scatter_unsigned:
    mov r9,[rsp+rax*8]
    mov [r13+r9*4],r11d
    inc qword [rsp+rax*8]
    inc r8
    cmp r8,r14
    jb .scatter
    xchg r12,r13
    add r15d,8
    cmp r15d,32
    jb .pass
    ; Even pass count returns the sorted values to the original input buffer.
.done:
    add rsp,2048
    pop r15
    pop r14
    pop r13
    pop r12
    ret
section .data align=16
values: dd 0,-1,2147483647,-2147483648,256,-256,1,0,65536,-65536,255,-255,42,-42,2,-2
expected: dd -2147483648,-65536,-256,-255,-42,-2,-1,0,0,1,2,42,255,256,65536,2147483647
single: dd -123
scratch: times 16 dd 0
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
