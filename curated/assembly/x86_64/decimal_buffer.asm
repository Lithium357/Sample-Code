; ISA: x86-64 integer instructions. NASM syntax, SysV AMD64 function ABI.
; Runtime: Linux ELF64 _start, exit(60) only. No libc. Not a Windows ABI binary.
; nasm -f elf64 decimal_buffer.asm -o decimal.o && ld decimal.o -o decimal && ./decimal
; -DFLAT -f bin selects the layout used by the Unicorn fixture runner.
bits 64
default rel
%ifdef FLAT
org 0x100000
%endif
section .text
global _start
_start:
    xor ebp, ebp                    ; fixture index
.case:
    ; Seed callee-saved registers; formatter must preserve all of them.
    mov ebx, 0x12345678
    mov r12d, 0x23456789
    mov r13d, 0x3456789a
    mov r14d, 0x456789ab
    mov r15d, 0x56789abc
    xor esi, esi                   ; try every capacity 0..12 for every value
.capacity:
    lea rdi, [guard]
    mov ecx, 16
    mov al, 0xa5
    rep stosb
    lea rdi, [buffer]
    lea rax, [numbers]
    mov edx, [rax+rbp*4]
    call decimal_u32
    cmp ebx, 0x12345678
    jne fail
    cmp r12d, 0x23456789
    jne fail
    cmp r13d, 0x3456789a
    jne fail
    cmp r14d, 0x456789ab
    jne fail
    cmp r15d, 0x56789abc
    jne fail
    lea rdx, [lengths]
    movzx ecx, byte [rdx+rbp]
    cmp rsi, rcx
    jb .short
    cmp rax, rcx
    jne fail
    mov r8, rbp
    imul r8, 10
    lea rdx, [expected]
    add rdx, r8
    xor r8d, r8d
.bytes:
    mov al, [rdx+r8]
    cmp al, [rdi+r8]
    jne fail
    inc r8
    cmp r8, rcx
    jb .bytes
    jmp .tail
.short:
    test rax, rax
    jnz fail
    xor r8d, r8d                   ; failure must leave entire destination alone
.tail:
    cmp byte [rdi+r8], 0xa5        ; includes byte after advertised capacity
    jne fail
    inc r8
    cmp r8, 14
    jb .tail
    cmp byte [guard], 0xa5
    jne fail
    cmp byte [guard+15], 0xa5
    jne fail
    inc esi
    cmp esi, 12
    jbe .capacity
    inc ebp
    cmp ebp, 8
    jb .case
    ; NULL is allowed only with capacity zero, which must not access destination.
    xor edi, edi
    xor esi, esi
    xor edx, edx
    call decimal_u32
    test eax, eax
    jnz fail
    xor edi, edi
    jmp exit
fail:
    mov edi, 1
exit:
    mov eax, 60
    syscall

; decimal_u32(dst:rdi, capacity:rsi, value:edx) -> rax length or 0.
; Writes digits WITHOUT a NUL terminator. Insufficient capacity writes nothing.
; Caller supplies a writable range of capacity bytes unless capacity==0.
; rdi/rsi are preserved as an additional convenience; flags/scratch regs clobbered.
decimal_u32:
    sub rsp, 16
    mov eax, edx                   ; zero extension is essential for UINT32_MAX
    xor ecx, ecx
    mov r9d, 10
.digit:
    xor edx, edx
    div r9d                        ; unsigned EDX:EAX / 10
    add dl, '0'
    mov [rsp+rcx], dl
    inc ecx
    test eax, eax
    jnz .digit
    cmp rsi, rcx
    jb .no_room
    mov eax, ecx
    xor r8d, r8d
.copy:
    dec ecx
    mov dl, [rsp+rcx]
    mov [rdi+r8], dl
    inc r8
    test ecx, ecx
    jnz .copy
    add rsp, 16
    ret
.no_room:
    xor eax, eax
    add rsp, 16
    ret

section .data
numbers: dd 0,1,9,10,99,100,2147483648,4294967295
lengths: db 1,1,1,2,2,3,10,10
; Fixed-width independent decimal literals, not computed by the formatter.
expected:
    db '0.........','1.........','9.........','10........'
    db '99........','100.......','2147483648','4294967295'
guard: times 16 db 0xa5
buffer equ guard+1
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
