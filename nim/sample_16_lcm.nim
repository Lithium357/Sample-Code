# Lcm.
# Nim 2.x; nim c -r FILE.nim
# Contract: a,b >= 0; zero arguments produce 0.
# Run this file independently; failures exit nonzero.

proc lcm(v_a_arg: int64, v_b_arg: int64): int64 =
    var v_a = v_a_arg
    var v_b = v_b_arg
    var v_remainder: int64 = 0
    var v_x: int64 = 0
    var v_y: int64 = 0
    if v_a == 0:
        return 0
    if v_b == 0:
        return 0
    v_x = v_a
    v_y = v_b
    while v_y != 0:
        v_remainder = (v_x mod v_y)
        v_x = v_y
        v_y = v_remainder
    return ((v_a div v_x) * v_b)

when isMainModule:
    doAssert lcm(12, 18) == 36, "lcm fixture 1: (12, 18) -> 36"
    doAssert lcm(0, 7) == 0, "lcm fixture 2: (0, 7) -> 0"
    doAssert lcm(7, 0) == 0, "lcm fixture 3: (7, 0) -> 0"
    doAssert lcm(5, 7) == 35, "lcm fixture 4: (5, 7) -> 35"
    doAssert lcm(9, 9) == 9, "lcm fixture 5: (9, 9) -> 9"
    echo "lcm: 5 fixtures passed"
