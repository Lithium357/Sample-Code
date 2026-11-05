# Nth prime.
# Nim 2.x; nim c -r FILE.nim
# Contract: 1 <= index <= 100; trial division is intended for small inputs.
# Run this file independently; failures exit nonzero.

proc nth_prime(v_index_arg: int64): int64 =
    var v_index = v_index_arg
    var v_candidate: int64 = 0
    var v_count: int64 = 0
    var v_divisor: int64 = 0
    var v_prime: int64 = 0
    v_count = 0
    v_candidate = 1
    while v_count < v_index:
        v_candidate = (v_candidate + 1)
        v_prime = 1
        v_divisor = 2
        while v_divisor <= (v_candidate div v_divisor):
            if (v_candidate mod v_divisor) == 0:
                v_prime = 0
            v_divisor = (v_divisor + 1)
        v_count = (v_count + v_prime)
    return v_candidate

when isMainModule:
    doAssert nth_prime(1) == 2, "nth_prime fixture 1: (1,) -> 2"
    doAssert nth_prime(2) == 3, "nth_prime fixture 2: (2,) -> 3"
    doAssert nth_prime(10) == 29, "nth_prime fixture 3: (10,) -> 29"
    doAssert nth_prime(25) == 97, "nth_prime fixture 4: (25,) -> 97"
    echo "nth_prime: 4 fixtures passed"
