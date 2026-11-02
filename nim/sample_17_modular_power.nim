# Modular power.
# Nim 2.x; nim c -r FILE.nim
# Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
# Run this file independently; failures exit nonzero.

proc modular_power(v_base_arg: int64, v_exponent_arg: int64, v_modulus_arg: int64): int64 =
    var v_base = v_base_arg
    var v_exponent = v_exponent_arg
    var v_modulus = v_modulus_arg
    var v_result: int64 = 0
    v_result = (1 mod v_modulus)
    v_base = (v_base mod v_modulus)
    while v_exponent > 0:
        if (v_exponent mod 2) == 1:
            v_result = ((v_result * v_base) mod v_modulus)
        v_exponent = (v_exponent div 2)
        v_base = ((v_base * v_base) mod v_modulus)
    return v_result

when isMainModule:
    doAssert modular_power(2, 10, 1000) == 24, "modular_power fixture 1: (2, 10, 1000) -> 24"
    doAssert modular_power(7, 0, 1) == 0, "modular_power fixture 2: (7, 0, 1) -> 0"
    doAssert modular_power(3, 4, 7) == 4, "modular_power fixture 3: (3, 4, 7) -> 4"
    doAssert modular_power(5, 3, 13) == 8, "modular_power fixture 4: (5, 3, 13) -> 8"
    echo "modular_power: 4 fixtures passed"
