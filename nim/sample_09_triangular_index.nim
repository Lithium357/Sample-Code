# Triangular index.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc triangular_index(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_index: int64 = 0
    var v_total: int64 = 0
    v_total = 0
    v_index = 0
    while v_total < v_n:
        v_index = (v_index + 1)
        v_total = (v_total + v_index)
    if v_total == v_n:
        return v_index
    return (-1)

when isMainModule:
    doAssert triangular_index(0) == 0, "triangular_index fixture 1: (0,) -> 0"
    doAssert triangular_index(1) == 1, "triangular_index fixture 2: (1,) -> 1"
    doAssert triangular_index(15) == 5, "triangular_index fixture 3: (15,) -> 5"
    doAssert triangular_index(14) == -1, "triangular_index fixture 4: (14,) -> -1"
    echo "triangular_index: 4 fixtures passed"
