# Factorial.
# Nim 2.x; nim c -r FILE.nim
# Contract: 0 <= n <= 12; larger values exceed CMD signed 32-bit arithmetic.
# Run this file independently; failures exit nonzero.

proc factorial(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_factor: int64 = 0
    var v_result: int64 = 0
    v_result = 1
    v_factor = 2
    while v_factor <= v_n:
        v_result = (v_result * v_factor)
        v_factor = (v_factor + 1)
    return v_result

when isMainModule:
    doAssert factorial(0) == 1, "factorial fixture 1: (0,) -> 1"
    doAssert factorial(1) == 1, "factorial fixture 2: (1,) -> 1"
    doAssert factorial(5) == 120, "factorial fixture 3: (5,) -> 120"
    doAssert factorial(10) == 3628800, "factorial fixture 4: (10,) -> 3628800"
    echo "factorial: 4 fixtures passed"
