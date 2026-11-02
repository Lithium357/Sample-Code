# Modular inverse.
# Nim 2.x; nim c -r FILE.nim
# Contract: a >= 0; modulus > 1; returns -1 when no inverse exists.
# Run this file independently; failures exit nonzero.

proc modular_inverse(v_a_arg: int64, v_modulus_arg: int64): int64 =
    var v_a = v_a_arg
    var v_modulus = v_modulus_arg
    var v_candidate: int64 = 0
    v_candidate = 1
    while v_candidate < v_modulus:
        if ((v_a * v_candidate) mod v_modulus) == 1:
            return v_candidate
        v_candidate = (v_candidate + 1)
    return (-1)

when isMainModule:
    doAssert modular_inverse(3, 7) == 5, "modular_inverse fixture 1: (3, 7) -> 5"
    doAssert modular_inverse(2, 4) == -1, "modular_inverse fixture 2: (2, 4) -> -1"
    doAssert modular_inverse(1, 5) == 1, "modular_inverse fixture 3: (1, 5) -> 1"
    doAssert modular_inverse(7, 11) == 8, "modular_inverse fixture 4: (7, 11) -> 8"
    echo "modular_inverse: 4 fixtures passed"
