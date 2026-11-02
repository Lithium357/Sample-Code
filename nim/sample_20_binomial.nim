# Binomial.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc binomial(v_n_arg: int64, v_k_arg: int64): int64 =
    var v_n = v_n_arg
    var v_k = v_k_arg
    var v_index: int64 = 0
    var v_result: int64 = 0
    if v_k > v_n:
        return 0
    if v_k > (v_n - v_k):
        v_k = (v_n - v_k)
    v_result = 1
    v_index = 1
    while v_index <= v_k:
        v_result = ((v_result * ((v_n - v_k) + v_index)) div v_index)
        v_index = (v_index + 1)
    return v_result

when isMainModule:
    doAssert binomial(5, 2) == 10, "binomial fixture 1: (5, 2) -> 10"
    doAssert binomial(0, 0) == 1, "binomial fixture 2: (0, 0) -> 1"
    doAssert binomial(6, 7) == 0, "binomial fixture 3: (6, 7) -> 0"
    doAssert binomial(10, 5) == 252, "binomial fixture 4: (10, 5) -> 252"
    echo "binomial: 4 fixtures passed"
