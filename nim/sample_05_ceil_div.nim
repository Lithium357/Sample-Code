# Ceil div.
# Nim 2.x; nim c -r FILE.nim
# Contract: numerator >= 0; denominator > 0.
# Run this file independently; failures exit nonzero.

proc ceil_div(v_numerator_arg: int64, v_denominator_arg: int64): int64 =
    var v_numerator = v_numerator_arg
    var v_denominator = v_denominator_arg
    var v_quotient: int64 = 0
    v_quotient = (v_numerator div v_denominator)
    if (v_numerator mod v_denominator) != 0:
        v_quotient = (v_quotient + 1)
    return v_quotient

when isMainModule:
    doAssert ceil_div(0, 3) == 0, "ceil_div fixture 1: (0, 3) -> 0"
    doAssert ceil_div(10, 3) == 4, "ceil_div fixture 2: (10, 3) -> 4"
    doAssert ceil_div(12, 3) == 4, "ceil_div fixture 3: (12, 3) -> 4"
    doAssert ceil_div(1, 9) == 1, "ceil_div fixture 4: (1, 9) -> 1"
    echo "ceil_div: 4 fixtures passed"
