# Gcd.
# Nim 2.x; nim c -r FILE.nim
# Contract: a,b >= 0; gcd(0,0) is defined as 0.
# Run this file independently; failures exit nonzero.

proc gcd(v_a_arg: int64, v_b_arg: int64): int64 =
    var v_a = v_a_arg
    var v_b = v_b_arg
    var v_remainder: int64 = 0
    while v_b != 0:
        v_remainder = (v_a mod v_b)
        v_a = v_b
        v_b = v_remainder
    return v_a

when isMainModule:
    doAssert gcd(48, 18) == 6, "gcd fixture 1: (48, 18) -> 6"
    doAssert gcd(0, 7) == 7, "gcd fixture 2: (0, 7) -> 7"
    doAssert gcd(7, 0) == 7, "gcd fixture 3: (7, 0) -> 7"
    doAssert gcd(0, 0) == 0, "gcd fixture 4: (0, 0) -> 0"
    doAssert gcd(35, 64) == 1, "gcd fixture 5: (35, 64) -> 1"
    echo "gcd: 5 fixtures passed"
