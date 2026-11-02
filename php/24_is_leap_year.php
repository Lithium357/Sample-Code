<?php
declare(strict_types=1);
// Is leap year.
// PHP 8.x CLI; php FILE.php
// Contract: year >= 1; proleptic Gregorian calendar.
// Run this file independently; failures exit nonzero.

function is_leap_year(int $v_year): int {
    if (($v_year % 400) == 0) {
        return 1;
    }
    if (($v_year % 100) == 0) {
        return 0;
    }
    if (($v_year % 4) == 0) {
        return 1;
    }
    return 0;
}

if (is_leap_year(1900) !== 0) {
    throw new RuntimeException("is_leap_year fixture 1: (1900,) -> 0");
}
if (is_leap_year(2000) !== 1) {
    throw new RuntimeException("is_leap_year fixture 2: (2000,) -> 1");
}
if (is_leap_year(2024) !== 1) {
    throw new RuntimeException("is_leap_year fixture 3: (2024,) -> 1");
}
if (is_leap_year(2023) !== 0) {
    throw new RuntimeException("is_leap_year fixture 4: (2023,) -> 0");
}
echo "is_leap_year: 4 fixtures passed\n";
