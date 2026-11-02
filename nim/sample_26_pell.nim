# Pell.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc pell(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_current: int64 = 0
    var v_following: int64 = 0
    var v_index: int64 = 0
    var v_previous: int64 = 0
    v_previous = 0
    v_current = 1
    v_index = 0
    while v_index < v_n:
        v_following = ((2 * v_current) + v_previous)
        v_previous = v_current
        v_current = v_following
        v_index = (v_index + 1)
    return v_previous

when isMainModule:
    doAssert pell(0) == 0, "pell fixture 1: (0,) -> 0"
    doAssert pell(1) == 1, "pell fixture 2: (1,) -> 1"
    doAssert pell(5) == 29, "pell fixture 3: (5,) -> 29"
    doAssert pell(10) == 2378, "pell fixture 4: (10,) -> 2378"
    echo "pell: 4 fixtures passed"
