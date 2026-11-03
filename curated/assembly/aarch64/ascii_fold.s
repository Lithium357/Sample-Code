// ISA: AArch64 Armv8-A, little-endian; GNU assembler syntax; AAPCS64.
// Function module only, no OS calls. x0=dst,x1=src,x2=n,x3=capacity; returns
// min(n,capacity) in x0. Caller provides disjoint valid copied ranges.
// ASCII lowercase folds to uppercase; other byte values, including NUL, remain.
// GNU native object command (not locally checked): aarch64-linux-gnu-as -o fold.o ascii_fold.s
// Local validation assembles ONLY the marked function body with Keystone and
// executes it under Unicorn. GNU directives/ELF linking are not thereby checked.
.text
.p2align 2
.global ascii_fold
.type ascii_fold, %function
// BEGIN FUNCTION
ascii_fold:
    cmp x2, x3
    csel x2, x2, x3, lo
    mov x4, #0
fold_loop:
    cmp x4, x2
    b.hs fold_done
    ldrb w5, [x1, x4]
    cmp w5, #97
    b.lo fold_store
    cmp w5, #122
    b.hi fold_store
    sub w5, w5, #32
fold_store:
    strb w5, [x0, x4]
    add x4, x4, #1
    b fold_loop
fold_done:
    mov x0, x4
    ret
// END FUNCTION
.size ascii_fold, .-ascii_fold
