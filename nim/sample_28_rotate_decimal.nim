# Rotate decimal.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc rotate_decimal(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_remaining: int64 = 0
    var v_scale: int64 = 0
    if v_n < 10:
        return v_n
    v_scale = 1
    v_remaining = v_n
    while v_remaining >= 10:
        v_scale = (v_scale * 10)
        v_remaining = (v_remaining div 10)
    return (((v_n mod 10) * v_scale) + (v_n div 10))

when isMainModule:
    doAssert rotate_decimal(0) == 0, "rotate_decimal fixture 1: (0,) -> 0"
    doAssert rotate_decimal(7) == 7, "rotate_decimal fixture 2: (7,) -> 7"
    doAssert rotate_decimal(1234) == 4123, "rotate_decimal fixture 3: (1234,) -> 4123"
    doAssert rotate_decimal(120) == 12, "rotate_decimal fixture 4: (120,) -> 12"
    echo "rotate_decimal: 4 fixtures passed"
