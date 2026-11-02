# Integer log.
# Nim 2.x; nim c -r FILE.nim
# Contract: n >= 1; base >= 2; returns floor(log_base(n)).
# Run this file independently; failures exit nonzero.

proc integer_log(v_n_arg: int64, v_base_arg: int64): int64 =
    var v_n = v_n_arg
    var v_base = v_base_arg
    var v_exponent: int64 = 0
    v_exponent = 0
    while v_n >= v_base:
        v_n = (v_n div v_base)
        v_exponent = (v_exponent + 1)
    return v_exponent

when isMainModule:
    doAssert integer_log(1, 2) == 0, "integer_log fixture 1: (1, 2) -> 0"
    doAssert integer_log(8, 2) == 3, "integer_log fixture 2: (8, 2) -> 3"
    doAssert integer_log(99, 10) == 1, "integer_log fixture 3: (99, 10) -> 1"
    doAssert integer_log(100, 10) == 2, "integer_log fixture 4: (100, 10) -> 2"
    echo "integer_log: 4 fixtures passed"
