# Is leap year.
# Nim 2.x; nim c -r FILE.nim
# Contract: year >= 1; proleptic Gregorian calendar.
# Run this file independently; failures exit nonzero.

proc is_leap_year(v_year_arg: int64): int64 =
    var v_year = v_year_arg
    if (v_year mod 400) == 0:
        return 1
    if (v_year mod 100) == 0:
        return 0
    if (v_year mod 4) == 0:
        return 1
    return 0

when isMainModule:
    doAssert is_leap_year(1900) == 0, "is_leap_year fixture 1: (1900,) -> 0"
    doAssert is_leap_year(2000) == 1, "is_leap_year fixture 2: (2000,) -> 1"
    doAssert is_leap_year(2024) == 1, "is_leap_year fixture 3: (2024,) -> 1"
    doAssert is_leap_year(2023) == 0, "is_leap_year fixture 4: (2023,) -> 0"
    echo "is_leap_year: 4 fixtures passed"
