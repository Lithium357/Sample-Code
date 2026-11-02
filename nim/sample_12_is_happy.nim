# Is happy.
# Nim 2.x; nim c -r FILE.nim
# Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
# Run this file independently; failures exit nonzero.

proc is_happy(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_digit: int64 = 0
    var v_steps: int64 = 0
    var v_total: int64 = 0
    v_steps = 0
    while v_steps < 100:
        if v_n == 1:
            return 1
        v_total = 0
        while v_n > 0:
            v_digit = (v_n mod 10)
            v_total = (v_total + (v_digit * v_digit))
            v_n = (v_n div 10)
        v_n = v_total
        v_steps = (v_steps + 1)
    return 0

when isMainModule:
    doAssert is_happy(1) == 1, "is_happy fixture 1: (1,) -> 1"
    doAssert is_happy(19) == 1, "is_happy fixture 2: (19,) -> 1"
    doAssert is_happy(2) == 0, "is_happy fixture 3: (2,) -> 0"
    doAssert is_happy(0) == 0, "is_happy fixture 4: (0,) -> 0"
    echo "is_happy: 4 fixtures passed"
