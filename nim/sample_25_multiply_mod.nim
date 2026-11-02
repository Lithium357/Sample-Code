# Multiply mod.
# Nim 2.x; nim c -r FILE.nim
# Contract: a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.
# Run this file independently; failures exit nonzero.

proc multiply_mod(v_a_arg: int64, v_b_arg: int64, v_modulus_arg: int64): int64 =
    var v_a = v_a_arg
    var v_b = v_b_arg
    var v_modulus = v_modulus_arg
    var v_result: int64 = 0
    v_result = 0
    v_a = (v_a mod v_modulus)
    while v_b > 0:
        if (v_b mod 2) == 1:
            v_result = ((v_result + v_a) mod v_modulus)
        v_a = ((v_a * 2) mod v_modulus)
        v_b = (v_b div 2)
    return v_result

when isMainModule:
    doAssert multiply_mod(12, 13, 7) == 2, "multiply_mod fixture 1: (12, 13, 7) -> 2"
    doAssert multiply_mod(0, 9, 3) == 0, "multiply_mod fixture 2: (0, 9, 3) -> 0"
    doAssert multiply_mod(123, 456, 97) == 22, "multiply_mod fixture 3: (123, 456, 97) -> 22"
    doAssert multiply_mod(5, 9, 1) == 0, "multiply_mod fixture 4: (5, 9, 1) -> 0"
    echo "multiply_mod: 4 fixtures passed"
