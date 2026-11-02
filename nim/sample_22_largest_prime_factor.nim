# Largest prime factor.
# Nim 2.x; nim c -r FILE.nim
# Contract: n >= 1; returns 1 for the empty factorization of 1.
# Run this file independently; failures exit nonzero.

proc largest_prime_factor(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_divisor: int64 = 0
    var v_largest: int64 = 0
    v_largest = 1
    v_divisor = 2
    while v_divisor <= (v_n div v_divisor):
        while (v_n mod v_divisor) == 0:
            v_largest = v_divisor
            v_n = (v_n div v_divisor)
        v_divisor = (v_divisor + 1)
    if v_n > 1:
        v_largest = v_n
    return v_largest

when isMainModule:
    doAssert largest_prime_factor(1) == 1, "largest_prime_factor fixture 1: (1,) -> 1"
    doAssert largest_prime_factor(12) == 3, "largest_prime_factor fixture 2: (12,) -> 3"
    doAssert largest_prime_factor(49) == 7, "largest_prime_factor fixture 3: (49,) -> 7"
    doAssert largest_prime_factor(97) == 97, "largest_prime_factor fixture 4: (97,) -> 97"
    echo "largest_prime_factor: 4 fixtures passed"
