# Trailing zero bits.
# Nim 2.x; nim c -r FILE.nim
# Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
# Run this file independently; failures exit nonzero.

proc trailing_zero_bits(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_count: int64 = 0
    if v_n == 0:
        return (-1)
    v_count = 0
    while (v_n mod 2) == 0:
        v_count = (v_count + 1)
        v_n = (v_n div 2)
    return v_count

when isMainModule:
    doAssert trailing_zero_bits(0) == -1, "trailing_zero_bits fixture 1: (0,) -> -1"
    doAssert trailing_zero_bits(1) == 0, "trailing_zero_bits fixture 2: (1,) -> 0"
    doAssert trailing_zero_bits(40) == 3, "trailing_zero_bits fixture 3: (40,) -> 3"
    doAssert trailing_zero_bits(64) == 6, "trailing_zero_bits fixture 4: (64,) -> 6"
    echo "trailing_zero_bits: 4 fixtures passed"
