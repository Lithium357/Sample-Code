# Digit sum.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc digit_sum(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_total: int64 = 0
    v_total = 0
    while v_n > 0:
        v_total = (v_total + (v_n mod 10))
        v_n = (v_n div 10)
    return v_total

when isMainModule:
    doAssert digit_sum(0) == 0, "digit_sum fixture 1: (0,) -> 0"
    doAssert digit_sum(12345) == 15, "digit_sum fixture 2: (12345,) -> 15"
    doAssert digit_sum(909) == 18, "digit_sum fixture 3: (909,) -> 18"
    doAssert digit_sum(1000) == 1, "digit_sum fixture 4: (1000,) -> 1"
    echo "digit_sum: 4 fixtures passed"
