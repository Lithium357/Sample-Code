# Lucas.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc lucas(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_current: int64 = 0
    var v_following: int64 = 0
    var v_index: int64 = 0
    var v_previous: int64 = 0
    v_previous = 2
    v_current = 1
    v_index = 0
    while v_index < v_n:
        v_following = (v_previous + v_current)
        v_previous = v_current
        v_current = v_following
        v_index = (v_index + 1)
    return v_previous

when isMainModule:
    doAssert lucas(0) == 2, "lucas fixture 1: (0,) -> 2"
    doAssert lucas(1) == 1, "lucas fixture 2: (1,) -> 1"
    doAssert lucas(5) == 11, "lucas fixture 3: (5,) -> 11"
    doAssert lucas(10) == 123, "lucas fixture 4: (10,) -> 123"
    echo "lucas: 4 fixtures passed"
