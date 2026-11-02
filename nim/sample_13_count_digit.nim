# Count digit.
# Nim 2.x; nim c -r FILE.nim
# Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
# Run this file independently; failures exit nonzero.

proc count_digit(v_n_arg: int64, v_target_arg: int64): int64 =
    var v_n = v_n_arg
    var v_target = v_target_arg
    var v_count: int64 = 0
    if v_n == 0:
        if v_target == 0:
            return 1
        return 0
    v_count = 0
    while v_n > 0:
        if (v_n mod 10) == v_target:
            v_count = (v_count + 1)
        v_n = (v_n div 10)
    return v_count

when isMainModule:
    doAssert count_digit(0, 0) == 1, "count_digit fixture 1: (0, 0) -> 1"
    doAssert count_digit(0, 1) == 0, "count_digit fixture 2: (0, 1) -> 0"
    doAssert count_digit(1001, 0) == 2, "count_digit fixture 3: (1001, 0) -> 2"
    doAssert count_digit(777, 7) == 3, "count_digit fixture 4: (777, 7) -> 3"
    echo "count_digit: 4 fixtures passed"
