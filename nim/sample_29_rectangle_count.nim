# Rectangle count.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc rectangle_count(v_width_arg: int64, v_height_arg: int64): int64 =
    var v_width = v_width_arg
    var v_height = v_height_arg
    var v_horizontal: int64 = 0
    var v_vertical: int64 = 0
    v_horizontal = ((v_width * (v_width + 1)) div 2)
    v_vertical = ((v_height * (v_height + 1)) div 2)
    return (v_horizontal * v_vertical)

when isMainModule:
    doAssert rectangle_count(0, 4) == 0, "rectangle_count fixture 1: (0, 4) -> 0"
    doAssert rectangle_count(1, 1) == 1, "rectangle_count fixture 2: (1, 1) -> 1"
    doAssert rectangle_count(2, 3) == 18, "rectangle_count fixture 3: (2, 3) -> 18"
    doAssert rectangle_count(4, 4) == 100, "rectangle_count fixture 4: (4, 4) -> 100"
    echo "rectangle_count: 4 fixtures passed"
