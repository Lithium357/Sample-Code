# ISA: RV64I, little-endian, no compressed instructions; GNU syntax; LP64 ABI.
# Function only, no OS calls. a0=dst,a1=src,a2=n,a3=capacity; returns min(n,cap).
# Caller supplies disjoint valid copied ranges. ASCII folding; unsigned bytes.
# Intended object: riscv64-linux-gnu-as -march=rv64i -mabi=lp64 -o fold.o ascii_fold.s
# Validation records distinguish syntax, linked-text emulation and native runs.
# GNU as/ld/objcopy plus Unicorn can exercise this function without an OS.
# Emulation does not validate native hardware, ELF loading or OS behavior.
.option norvc
.option norelax
.text
.align 2
.globl ascii_fold
.type ascii_fold, @function
ascii_fold:
    bgeu a3, a2, limit_ready
    mv a2, a3
limit_ready:
    li t0, 0
fold_loop:
    bgeu t0, a2, fold_done
    add t2, a1, t0
    lbu t1, 0(t2)
    li t2, 97
    bltu t1, t2, fold_store
    li t2, 123
    bgeu t1, t2, fold_store
    addi t1, t1, -32
fold_store:
    add t2, a0, t0
    sb t1, 0(t2)
    addi t0, t0, 1
    j fold_loop
fold_done:
    mv a0, t0
    ret
.size ascii_fold, .-ascii_fold
