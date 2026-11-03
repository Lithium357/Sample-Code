@ ISA: ARMv7-A A32 (not Thumb), little-endian; GNU unified syntax; AAPCS32.
@ Function: r0=dst,r1=src,r2=n,r3=capacity; returns min(n,capacity) in r0.
@ Caller supplies disjoint valid copied ranges. ASCII lowercase only; NUL and
@ high bytes are copied unchanged. No OS calls or floating-point ABI dependency.
@ Intended object: arm-linux-gnueabi-as -march=armv7-a -o fold.o ascii_fold.s
@ Local check: marked body via Keystone + Unicorn; GNU directives not checked.
.syntax unified
.arm
.text
.align 2
.global ascii_fold
.type ascii_fold, %function
@ BEGIN FUNCTION
ascii_fold:
    cmp r2, r3
    movhi r2, r3
    mov r12, #0
fold_loop:
    cmp r12, r2
    bhs fold_done
    ldrb r3, [r1, r12]
    cmp r3, #97
    blo fold_store
    cmp r3, #122
    subls r3, r3, #32
fold_store:
    strb r3, [r0, r12]
    add r12, r12, #1
    b fold_loop
fold_done:
    mov r0, r12
    bx lr
@ END FUNCTION
.size ascii_fold, .-ascii_fold
