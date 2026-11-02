# Totient.
# Nim 2.x; nim c -r FILE.nim
# Contract: n >= 1.
# Run this file independently; failures exit nonzero.

proc totient(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_prime: int64 = 0
    var v_remaining: int64 = 0
    var v_result: int64 = 0
    v_result = v_n
    v_prime = 2
    v_remaining = v_n
    while v_prime <= (v_remaining div v_prime):
        if (v_remaining mod v_prime) == 0:
            while (v_remaining mod v_prime) == 0:
                v_remaining = (v_remaining div v_prime)
            v_result = (v_result - (v_result div v_prime))
        v_prime = (v_prime + 1)
    if v_remaining > 1:
        v_result = (v_result - (v_result div v_remaining))
    return v_result

when isMainModule:
    doAssert totient(1) == 1, "totient fixture 1: (1,) -> 1"
    doAssert totient(9) == 6, "totient fixture 2: (9,) -> 6"
    doAssert totient(12) == 4, "totient fixture 3: (12,) -> 4"
    doAssert totient(97) == 96, "totient fixture 4: (97,) -> 96"
    echo "totient: 4 fixtures passed"
