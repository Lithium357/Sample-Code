
unpack_s24le:
 mov x19, #0
cmp x3, #32
b.hi unpack_count
add x5, x3, x3, lsl #1
cmp x1, x5
b.lo unpack_short
mov x1, x5
mov x4, x0
cbz x3, unpack_done
unpack_loop:
ldrb w6, [x4]
ldrb w7, [x4, #1]
ldrb w8, [x4, #2]
orr w6, w6, w7, lsl #8
orr w6, w6, w8, lsl #16
sbfx w6, w6, #0, #24
str w6, [x2], #4
add x4, x4, #3
subs x3, x3, #1
b.ne unpack_loop
unpack_done:
mov w0, #0
ret
unpack_short:
mov w0, #1
mov x1, #0
ret
unpack_count:
mov w0, #2
mov x1, #0
ret

visit_s24le:
cmp x2, #32
b.hi visit_count
add x5, x2, x2, lsl #1
cmp x1, x5
b.lo visit_short
cbz x2, visit_empty
stp x29, x30, [sp, #-64]!
mov x29, sp
stp x19, x20, [sp, #16]
stp x21, x22, [sp, #32]
str x23, [sp, #48]
mov x19, x0
mov x20, x2
mov x21, x3
mov x22, x4
mov x23, #0
visit_loop:
ldrb w6, [x19]
ldrb w7, [x19, #1]
ldrb w8, [x19, #2]
orr w6, w6, w7, lsl #8
orr w6, w6, w8, lsl #16
sbfx x1, x6, #0, #24
mov x0, x22
mov x2, x23
blr x21
add x23, x23, #1
add x19, x19, #3
cbnz x0, visit_stopped
cmp x23, x20
b.lo visit_loop
mov w0, #0
b visit_return
visit_stopped:
mov w0, #3
visit_return:
add x1, x23, x23, lsl #1
ldr x23, [sp, #48]
ldp x21, x22, [sp, #32]
ldp x19, x20, [sp, #16]
ldp x29, x30, [sp], #64
ret
visit_empty:
mov w0, #0
mov x1, #0
ret
visit_short:
mov w0, #1
mov x1, #0
ret
visit_count:
mov w0, #2
mov x1, #0
ret