<?php
declare(strict_types=1);
// Is armstrong.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function is_armstrong(int $v_n): int {
    $v_digits = 1;
    $v_remaining = $v_n;
    while ($v_remaining >= 10) {
        $v_digits = ($v_digits + 1);
        $v_remaining = intdiv($v_remaining, 10);
    }
    $v_total = 0;
    $v_remaining = $v_n;
    while ($v_remaining > 0) {
        $v_digit = ($v_remaining % 10);
        $v_product = 1;
        $v_exponent = 0;
        while ($v_exponent < $v_digits) {
            $v_product = ($v_product * $v_digit);
            $v_exponent = ($v_exponent + 1);
        }
        $v_total = ($v_total + $v_product);
        $v_remaining = intdiv($v_remaining, 10);
    }
    if ($v_total == $v_n) {
        return 1;
    }
    return 0;
}

if (is_armstrong(0) !== 1) {
    throw new RuntimeException("is_armstrong fixture 1: (0,) -> 1");
}
if (is_armstrong(153) !== 1) {
    throw new RuntimeException("is_armstrong fixture 2: (153,) -> 1");
}
if (is_armstrong(9474) !== 1) {
    throw new RuntimeException("is_armstrong fixture 3: (9474,) -> 1");
}
if (is_armstrong(154) !== 0) {
    throw new RuntimeException("is_armstrong fixture 4: (154,) -> 0");
}
echo "is_armstrong: 4 fixtures passed\n";
