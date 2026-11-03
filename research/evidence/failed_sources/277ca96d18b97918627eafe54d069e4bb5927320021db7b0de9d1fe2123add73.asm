; ISA: x86-64; NASM syntax; SysV AMD64 integer ABI; little endian.
; decode_uleb32(src:rdi, available:rsi, out:rdx) -> eax status:
; 0 success, 1 truncated, 2 overflow, 3 noncanonical (redundant last zero).
; Success writes exactly eight bytes: u32 LE value, u32 LE consumed count.
; Failure writes nothing. Input/output may overlap: every input byte is read
; before the first output store. Output need not be aligned. Caller supplies
; valid readable/writable ranges; NULL source is allowed with available==0.
; Only the first encoding is decoded; no trailing input is inspected.
; Native fixture: nasm -f elf64 uleb32.asm -o check.o && ld check.o -o check && ./check
; Linux ELF64 _start uses exit(60), no libc. Not a Windows ABI executable.
; -DFLAT -f bin places the function first for the bounded-access emulator tests.
bits 64
default rel
%ifdef FLAT
org 0x100000
%endif
section .text
global decode_uleb32
decode_uleb32:
    xor r8d, r8d                   ; accumulator
    xor r9d, r9d                   ; byte index
    xor r10d, r10d                 ; bit position
.loop:
    cmp r9, rsi                    ; available is unsigned size_t, not signed
    jae .truncated
    movzx eax, byte [rdi+r9]
    cmp r9d, 4
    jne .accumulate
    cmp eax, 15                    ; fifth byte: no continuation/high payload
    ja .overflow
.accumulate:
    mov r11d, eax
    and r11d, 127
    mov ecx, r10d
    shl r11d, cl
    or r8d, r11d
    test al, 128
    jnz .more
    test r9d, r9d
    jz .success
    test al, 127
    jz .noncanonical
.success:
    mov [rdx], r8d
    inc r9d
    mov [rdx+4], r9d
    xor eax, eax
    ret
.more:
    inc r9d
    add r10d, 7
    jmp .loop
.truncated:
    mov eax, 1
    ret
.overflow:
    mov eax, 2
    ret
.noncanonical:
    mov eax, 3
    ret

; Independent native literals and full destination guards. The companion
; emulator additionally checks each access, aliases, unsigned large bounds,
; all preserved registers and hundreds of division-based oracle vectors.
global _start
_start:
    cld
    lea rbx, [cases]
    mov ebp, case_count
.case:
    lea rdi, [guard]
    mov ecx, 16
    mov al, 0xa5
    rep stosb
    mov r12d, 0x12345678
    mov r13d, 0x23456789
    mov r14d, 0x3456789a
    mov r15d, 0x456789ab
    mov [saved_stack], rsp
    mov [saved_table], rbx
    mov [saved_count], rbp
    mov rdi, [rbx]
    mov rsi, [rbx+8]
    lea rdx, [guard+3]
    call decode_uleb32
    cmp rsp, [saved_stack]
    jne fail
    cmp rbx, [saved_table]
    jne fail
    cmp rbp, [saved_count]
    jne fail
    cmp r12d, 0x12345678
    jne fail
    cmp r13d, 0x23456789
    jne fail
    cmp r14d, 0x3456789a
    jne fail
    cmp r15d, 0x456789ab
    jne fail
    cmp eax, [rbx+16]
    jne fail
    test eax, eax
    jnz .check_all
    mov eax, [guard+3]
    cmp eax, [rbx+20]
    jne fail
    mov eax, [guard+7]
    cmp eax, [rbx+24]
    jne fail
    xor ecx, ecx
.check_edges:
    cmp ecx, 3
    jb .guard_byte
    cmp ecx, 11
    jb .next_edge
.guard_byte:
    lea rdx, [guard]
    cmp byte [rdx+rcx], 0xa5
    jne fail
.next_edge:
    inc ecx
    cmp ecx, 16
    jb .check_edges
    jmp .next
.check_all:
    lea rdx, [guard]
    xor ecx, ecx
.unchanged:
    cmp byte [rdx+rcx], 0xa5
    jne fail
    inc ecx
    cmp ecx, 16
    jb .unchanged
.next:
    add rbx, 32
    dec ebp
    jnz .case
    xor edi, edi
    jmp exit
fail:
    mov edi, 1
exit:
    mov eax, 60
    syscall

section .data
zero: db 0
one: db 1, 0xff, 0xff              ; trailing bytes must not be read
edge: db 0x7f
two: db 0x80, 1
three: db 0x80, 0x80, 1
high: db 0x80, 0x80, 0x80, 0x80, 8
largest: db 0xff, 0xff, 0xff, 0xff, 15
bad: db 0xff, 0xff, 0xff, 0xff, 16
continued: db 0x80, 0x80, 0x80, 0x80, 0x80
redundant: db 0x80, 0
redundant_one: db 0x81, 0
; source pointer, available, status, value, consumed, padding (32 bytes).
cases:
    dq 0, 0
    dd 1, 0, 0, 0
    dq zero, 1
    dd 0, 0, 1, 0
    dq one, 3
    dd 0, 1, 1, 0
    dq edge, 1
    dd 0, 127, 1, 0
    dq two, 2
    dd 0, 128, 2, 0
    dq three, 3
    dd 0, 16384, 3, 0
    dq high, 5
    dd 0, 2147483648, 5, 0
    dq largest, 5
    dd 0, 4294967295, 5, 0
    dq bad, 5
    dd 2, 0, 0, 0
    dq continued, 5
    dd 2, 0, 0, 0
    dq continued, 4
    dd 1, 0, 0, 0
    dq redundant, 2
    dd 3, 0, 0, 0
    dq redundant_one, 2
    dd 3, 0, 0, 0
    dq high, 4
    dd 1, 0, 0, 0
    dq two, 0x8000000000000000
    dd 0, 128, 2, 0
    dq largest, 0xffffffffffffffff
    dd 0, 4294967295, 5, 0
case_count equ ($-cases)/32
guard: times 16 db 0xa5
saved_stack: dq 0
saved_table: dq 0
saved_count: dq 0
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
