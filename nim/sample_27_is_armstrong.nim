# Is armstrong.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc is_armstrong(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_digit: int64 = 0
    var v_digits: int64 = 0
    var v_exponent: int64 = 0
    var v_product: int64 = 0
    var v_remaining: int64 = 0
    var v_total: int64 = 0
    v_digits = 1
    v_remaining = v_n
    while v_remaining >= 10:
        v_digits = (v_digits + 1)
        v_remaining = (v_remaining div 10)
    v_total = 0
    v_remaining = v_n
    while v_remaining > 0:
        v_digit = (v_remaining mod 10)
        v_product = 1
        v_exponent = 0
        while v_exponent < v_digits:
            v_product = (v_product * v_digit)
            v_exponent = (v_exponent + 1)
        v_total = (v_total + v_product)
        v_remaining = (v_remaining div 10)
    if v_total == v_n:
        return 1
    return 0

when isMainModule:
    doAssert is_armstrong(0) == 1, "is_armstrong fixture 1: (0,) -> 1"
    doAssert is_armstrong(153) == 1, "is_armstrong fixture 2: (153,) -> 1"
    doAssert is_armstrong(9474) == 1, "is_armstrong fixture 3: (9474,) -> 1"
    doAssert is_armstrong(154) == 0, "is_armstrong fixture 4: (154,) -> 0"
    echo "is_armstrong: 4 fixtures passed"
