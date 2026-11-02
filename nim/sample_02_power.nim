# Power.
# Nim 2.x; nim c -r FILE.nim
# Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
# Run this file independently; failures exit nonzero.

proc power(v_base_arg: int64, v_exponent_arg: int64): int64 =
    var v_base = v_base_arg
    var v_exponent = v_exponent_arg
    var v_result: int64 = 0
    v_result = 1
    while v_exponent > 0:
        if (v_exponent mod 2) == 1:
            v_result = (v_result * v_base)
        v_exponent = (v_exponent div 2)
        if v_exponent > 0:
            v_base = (v_base * v_base)
    return v_result

when isMainModule:
    doAssert power(0, 0) == 1, "power fixture 1: (0, 0) -> 1"
    doAssert power(2, 10) == 1024, "power fixture 2: (2, 10) -> 1024"
    doAssert power(3, 5) == 243, "power fixture 3: (3, 5) -> 243"
    doAssert power(7, 1) == 7, "power fixture 4: (7, 1) -> 7"
    echo "power: 4 fixtures passed"
