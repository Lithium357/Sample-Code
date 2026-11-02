# Is prime.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc is_prime(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_divisor: int64 = 0
    if v_n < 2:
        return 0
    v_divisor = 2
    while v_divisor <= (v_n div v_divisor):
        if (v_n mod v_divisor) == 0:
            return 0
        v_divisor = (v_divisor + 1)
    return 1

when isMainModule:
    doAssert is_prime(0) == 0, "is_prime fixture 1: (0,) -> 0"
    doAssert is_prime(1) == 0, "is_prime fixture 2: (1,) -> 0"
    doAssert is_prime(2) == 1, "is_prime fixture 3: (2,) -> 1"
    doAssert is_prime(49) == 0, "is_prime fixture 4: (49,) -> 0"
    doAssert is_prime(97) == 1, "is_prime fixture 5: (97,) -> 1"
    echo "is_prime: 5 fixtures passed"
