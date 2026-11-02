# Is palindrome.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc is_palindrome(v_n_arg: int64): int64 =
    var v_n = v_n_arg
    var v_original: int64 = 0
    var v_reversed_value: int64 = 0
    v_original = v_n
    v_reversed_value = 0
    while v_n > 0:
        v_reversed_value = ((v_reversed_value * 10) + (v_n mod 10))
        v_n = (v_n div 10)
    if v_reversed_value == v_original:
        return 1
    return 0

when isMainModule:
    doAssert is_palindrome(0) == 1, "is_palindrome fixture 1: (0,) -> 1"
    doAssert is_palindrome(1221) == 1, "is_palindrome fixture 2: (1221,) -> 1"
    doAssert is_palindrome(123) == 0, "is_palindrome fixture 3: (123,) -> 0"
    doAssert is_palindrome(101) == 1, "is_palindrome fixture 4: (101,) -> 1"
    echo "is_palindrome: 4 fixtures passed"
