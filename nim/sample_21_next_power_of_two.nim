# Next power of two.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc next_power_of_two(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_result: int64 = 0
    v_result = 1
    while v_result < v_n:
        v_result = (v_result * 2)
    return v_result

when isMainModule:
    doAssert next_power_of_two(0) == 1, "next_power_of_two fixture 1: (0,) -> 1"
    doAssert next_power_of_two(1) == 1, "next_power_of_two fixture 2: (1,) -> 1"
    doAssert next_power_of_two(9) == 16, "next_power_of_two fixture 3: (9,) -> 16"
    doAssert next_power_of_two(64) == 64, "next_power_of_two fixture 4: (64,) -> 64"
    echo "next_power_of_two: 4 fixtures passed"
