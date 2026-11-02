; Incremental IEEE CRC32 using bitwise polynomial reduction, no CPU extensions.
; NASM x86-64 Linux; this is an integrity checksum, not a cryptographic hash.
; nasm -f elf64 crc32_ieee.asm -o crc.o && ld crc.o -o crc && ./crc
; Optional emulator image: nasm -DFLAT -f bin ...
bits 64
default rel
%ifdef FLAT
org 0x100000
%else
global _start
%endif
section .text
_start:
    lea rdi,[rel vector]
    mov esi,9
    xor edx,edx
    call crc_update
    cmp eax,0xcbf43926
    jne fail
    ; Every split must match the checksum computed in one call. API takes the
    ; previously finalized CRC, so callers never manipulate internal complements.
    xor r12d,r12d
.split:
    lea rdi,[rel vector]
    mov rsi,r12
    xor edx,edx
    call crc_update
    mov edx,eax
    lea rdi,[rel vector]
    add rdi,r12
    mov esi,9
    sub rsi,r12
    call crc_update
    cmp eax,0xcbf43926
    jne fail
    inc r12
    cmp r12,9
    jbe .split
    xor edi,edi
    xor esi,esi
    xor edx,edx
    call crc_update
    test eax,eax
    jnz fail
    ; A longer binary vector checks all byte values, including NUL and 0xff.
    lea rdi,[rel binary]
    xor ecx,ecx
.fill:
    mov [rdi+rcx],cl
    inc ecx
    cmp ecx,256
    jb .fill
    mov esi,256
    xor edx,edx
    call crc_update
    cmp eax,0x29058c73
    jne fail
    mov r13d,eax
    lea r14,[rel binary]
    xor r12d,r12d
    xor edx,edx
.bytewise:
    lea rdi,[r14+r12]
    mov esi,1
    call crc_update
    mov edx,eax
    inc r12
    cmp r12,256
    jb .bytewise
    cmp eax,r13d
    jne fail
    xor edi,edi
    mov eax,60
    syscall
fail:
    mov edi,1
    mov eax,60
    syscall

; crc_update(bytes=RDI,length=RSI,previous_finalized_crc=EDX) -> EAX.
; Init with zero. Zero-length input returns previous CRC without dereferencing.
; Valid readable ranges are a caller precondition. Callee-saved registers intact.
crc_update:
    mov eax,edx
    not eax
    test rsi,rsi
    jz .finish
.byte:
    movzx ecx,byte [rdi]
    xor eax,ecx
    mov ecx,8
.bit:
    mov r8d,eax
    and r8d,1
    neg r8d
    and r8d,0xedb88320
    shr eax,1
    xor eax,r8d
    dec ecx
    jnz .bit
    inc rdi
    dec rsi
    jnz .byte
.finish:
    not eax
    ret
section .data align=16
vector: db '123456789'
binary: times 256 db 0
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
