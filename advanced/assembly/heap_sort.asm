; In-place signed int64 heapsort. NASM syntax, x86-64 Linux, System V ABI.
; nasm -f elf64 heap_sort.asm -o heap.o && ld heap.o -o heap && ./heap
; Optional flat image for emulator tests: nasm -DFLAT -f bin heap_sort.asm -o heap.bin
; O(n log n) time, O(1) auxiliary storage; no allocation or external libraries.
bits 64
default rel
%ifdef FLAT
org 0x100000
%else
global _start
%endif
section .text
_start:
    lea rdi, [rel values]
    mov esi, 12
    call heap_sort
    lea rdi, [rel values]
    lea rsi, [rel expected]
    mov ecx, 12
.check:
    mov rax, [rdi]
    cmp rax, [rsi]
    jne fail
    add rdi, 8
    add rsi, 8
    loop .check
    ; Empty input must not dereference its pointer.
    xor edi, edi
    xor esi, esi
    call heap_sort
    lea rdi, [rel singleton]
    mov esi, 1
    call heap_sort
    cmp qword [rel singleton], -7
    jne fail
    ; Sorting already sorted data must be idempotent.
    lea rdi, [rel values]
    mov esi, 12
    call heap_sort
    lea rdi, [rel values]
    lea rsi, [rel expected]
    mov ecx, 12
.recheck:
    mov rax, [rdi]
    cmp rax, [rsi]
    jne fail
    add rdi, 8
    add rsi, 8
    loop .recheck
    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, 1
    mov eax, 60
    syscall

; heap_sort(int64_t *values, uint64_t length). Preserves callee-saved registers.
; Caller supplies a valid writable array with length*8 representable in memory.
heap_sort:
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    cmp r13, 2
    jb .done
    mov r14, r13
    shr r14, 1
.build:
    dec r14
    mov rdi, r12
    mov rsi, r14
    mov rdx, r13
    call sift_down
    test r14, r14
    jnz .build
    mov r14, r13
.extract:
    dec r14
    mov rax, [r12]
    mov rcx, [r12+r14*8]
    mov [r12], rcx
    mov [r12+r14*8], rax
    mov rdi, r12
    xor esi, esi
    mov rdx, r14
    call sift_down
    cmp r14, 1
    ja .extract
.done:
    pop r14
    pop r13
    pop r12
    ret

; sift_down(base=RDI, root=RSI, exclusive_end=RDX).
; Internal helper uses only caller-saved registers. Compare values as signed,
; indices as unsigned: the distinction matters for negative data and int64 min.
sift_down:
    mov rax, rsi
.next:
    lea rcx, [rax*2+1]
    cmp rcx, rdx
    jae .done
    lea r9, [rcx+1]
    cmp r9, rdx
    jae .chosen
    mov r8, [rdi+rcx*8]
    cmp r8, [rdi+r9*8]
    jge .chosen
    mov rcx, r9
.chosen:
    mov r8, [rdi+rax*8]
    mov r10, [rdi+rcx*8]
    cmp r8, r10
    jge .done
    mov [rdi+rax*8], r10
    mov [rdi+rcx*8], r8
    mov rax, rcx
    jmp .next
.done:
    ret

section .data align=16
values: dq -5,9,0,9,-9223372036854775808,9223372036854775807,-1,3,-5,4,2,1
expected: dq -9223372036854775808,-5,-5,-1,0,1,2,3,4,9,9,9223372036854775807
singleton: dq -7
%ifndef FLAT
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
