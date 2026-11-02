; Strict UTF-8 scalar-value validation and codepoint count, without libc.
; nasm -f elf64 utf8_validate.asm -o utf8.o && ld utf8.o -o utf8 && ./utf8
; Linux x86-64, System V ABI. Flat emulator image: nasm -DFLAT -f bin ...
; Rejects overlong encodings, surrogates, >U+10FFFF, stray continuation bytes,
; invalid leading bytes and truncated sequences. Embedded NUL is valid UTF-8.
bits 64
default rel
%ifdef FLAT
org 0x100000
%else
global _start
%endif
section .text
_start:
    lea r12, [rel fixtures]
    mov r13d, (fixtures_end-fixtures)/24
.test:
    mov rdi, [r12]
    mov rsi, [r12+8]
    call utf8_count
    cmp rax, [r12+16]
    jne fail
    add r12, 24
    dec r13
    jnz .test
    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, 1
    mov eax, 60
    syscall

; utf8_count(bytes=RDI,length=RSI) -> scalar count in RAX, or -1 if invalid.
; The caller supplies readable bytes for the declared length; no bytes outside
; that range are touched. Callee-saved registers remain unchanged.
utf8_count:
    xor r8d, r8d
.next:
    test rsi, rsi
    jz .done
    movzx eax, byte [rdi]
    cmp eax, 0x80
    jb .ascii
    cmp eax, 0xc2
    jb .bad
    mov r9d, 2
    cmp eax, 0xdf
    jbe .length_ready
    mov r9d, 3
    cmp eax, 0xef
    jbe .length_ready
    mov r9d, 4
    cmp eax, 0xf4
    ja .bad
.length_ready:
    cmp rsi, r9
    jb .bad
    movzx edx, byte [rdi+1]
    cmp eax, 0xe0
    jne .not_e0
    cmp edx, 0xa0
    jb .bad
.not_e0:
    cmp eax, 0xed
    jne .not_ed
    cmp edx, 0x9f
    ja .bad
.not_ed:
    cmp eax, 0xf0
    jne .not_f0
    cmp edx, 0x90
    jb .bad
.not_f0:
    cmp eax, 0xf4
    jne .continuations
    cmp edx, 0x8f
    ja .bad
.continuations:
    mov r10d, 1
.check_byte:
    movzx edx, byte [rdi+r10]
    and edx, 0xc0
    cmp edx, 0x80
    jne .bad
    inc r10
    cmp r10, r9
    jb .check_byte
    add rdi, r9
    sub rsi, r9
    inc r8
    jmp .next
.ascii:
    inc rdi
    dec rsi
    inc r8
    jmp .next
.done:
    mov rax, r8
    ret
.bad:
    mov rax, -1
    ret

section .data align=16
ascii: db 'hello'
mixed: db 'A',0xc2,0xa2,0xe2,0x82,0xac,0xf0,0x9f,0x98,0x80
limits: db 0,0x7f,0xc2,0x80,0xdf,0xbf,0xe0,0xa0,0x80,0xed,0x9f,0xbf,0xf4,0x8f,0xbf,0xbf
stray: db 0x80
overlong2: db 0xc0,0xaf
overlong3: db 0xe0,0x80,0x80
surrogate: db 0xed,0xa0,0x80
overlong4: db 0xf0,0x80,0x80,0x80
too_large: db 0xf4,0x90,0x80,0x80
bad_lead: db 0xf5,0x80,0x80,0x80
truncated: db 0xe2,0x82
bad_continuation: db 0xe2,0x28,0xa1
fixtures:
    dq 0,0,0
    dq ascii,5,5
    dq mixed,10,4
    dq limits,16,7
    dq stray,1,-1
    dq overlong2,2,-1
    dq overlong3,3,-1
    dq surrogate,3,-1
    dq overlong4,4,-1
    dq too_large,4,-1
    dq bad_lead,4,-1
    dq truncated,2,-1
    dq bad_continuation,3,-1
    dq mixed,9,-1
fixtures_end:
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
