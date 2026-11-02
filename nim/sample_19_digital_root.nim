# Digital root.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc digital_root(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_total: int64 = 0
    while v_n >= 10:
        v_total = 0
        while v_n > 0:
            v_total = (v_total + (v_n mod 10))
            v_n = (v_n div 10)
        v_n = v_total
    return v_n

when isMainModule:
    doAssert digital_root(0) == 0, "digital_root fixture 1: (0,) -> 0"
    doAssert digital_root(999) == 9, "digital_root fixture 2: (999,) -> 9"
    doAssert digital_root(12345) == 6, "digital_root fixture 3: (12345,) -> 6"
    doAssert digital_root(8) == 8, "digital_root fixture 4: (8,) -> 8"
    echo "digital_root: 4 fixtures passed"
