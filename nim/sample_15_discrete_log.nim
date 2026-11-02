# Discrete log.
# Nim 2.x; nim c -r FILE.nim
# Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
# Run this file independently; failures exit nonzero.

proc discrete_log(v_base_arg: int64, v_target_arg: int64, v_modulus_arg: int64): int64 =
    var v_base = v_base_arg
    var v_target = v_target_arg
    var v_modulus = v_modulus_arg
    var v_exponent: int64 = 0
    var v_value: int64 = 0
    v_value = (1 mod v_modulus)
    v_exponent = 0
    while v_exponent < v_modulus:
        if v_value == v_target:
            return v_exponent
        v_value = ((v_value * v_base) mod v_modulus)
        v_exponent = (v_exponent + 1)
    return (-1)

when isMainModule:
    doAssert discrete_log(2, 1, 7) == 0, "discrete_log fixture 1: (2, 1, 7) -> 0"
    doAssert discrete_log(2, 4, 7) == 2, "discrete_log fixture 2: (2, 4, 7) -> 2"
    doAssert discrete_log(2, 3, 7) == -1, "discrete_log fixture 3: (2, 3, 7) -> -1"
    doAssert discrete_log(3, 5, 7) == 5, "discrete_log fixture 4: (3, 5, 7) -> 5"
    echo "discrete_log: 4 fixtures passed"
