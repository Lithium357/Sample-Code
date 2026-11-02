<?php
declare(strict_types=1);
// Is palindrome.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function is_palindrome(int $v_n): int {
    $v_original = $v_n;
    $v_reversed_value = 0;
    while ($v_n > 0) {
        $v_reversed_value = (($v_reversed_value * 10) + ($v_n % 10));
        $v_n = intdiv($v_n, 10);
    }
    if ($v_reversed_value == $v_original) {
        return 1;
    }
    return 0;
}

if (is_palindrome(0) !== 1) {
    throw new RuntimeException("is_palindrome fixture 1: (0,) -> 1");
}
if (is_palindrome(1221) !== 1) {
    throw new RuntimeException("is_palindrome fixture 2: (1221,) -> 1");
}
if (is_palindrome(123) !== 0) {
    throw new RuntimeException("is_palindrome fixture 3: (123,) -> 0");
}
if (is_palindrome(101) !== 1) {
    throw new RuntimeException("is_palindrome fixture 4: (101,) -> 1");
}
echo "is_palindrome: 4 fixtures passed\n";
