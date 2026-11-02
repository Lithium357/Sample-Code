# Is perfect.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc is_perfect(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_divisor: int64 = 0
    var v_total: int64 = 0
    v_total = 0
    v_divisor = 1
    while v_divisor < v_n:
        if (v_n mod v_divisor) == 0:
            v_total = (v_total + v_divisor)
        v_divisor = (v_divisor + 1)
    if v_total == v_n:
        if v_n > 0:
            return 1
    return 0

when isMainModule:
    doAssert is_perfect(0) == 0, "is_perfect fixture 1: (0,) -> 0"
    doAssert is_perfect(1) == 0, "is_perfect fixture 2: (1,) -> 0"
    doAssert is_perfect(6) == 1, "is_perfect fixture 3: (6,) -> 1"
    doAssert is_perfect(28) == 1, "is_perfect fixture 4: (28,) -> 1"
    doAssert is_perfect(12) == 0, "is_perfect fixture 5: (12,) -> 0"
    echo "is_perfect: 5 fixtures passed"
