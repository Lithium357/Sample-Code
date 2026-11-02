<?php
declare(strict_types=1);
// Digit sum.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function digit_sum(int $v_n): int {
    $v_total = 0;
    while ($v_n > 0) {
        $v_total = ($v_total + ($v_n % 10));
        $v_n = intdiv($v_n, 10);
    }
    return $v_total;
}

if (digit_sum(0) !== 0) {
    throw new RuntimeException("digit_sum fixture 1: (0,) -> 0");
}
if (digit_sum(12345) !== 15) {
    throw new RuntimeException("digit_sum fixture 2: (12345,) -> 15");
}
if (digit_sum(909) !== 18) {
    throw new RuntimeException("digit_sum fixture 3: (909,) -> 18");
}
if (digit_sum(1000) !== 1) {
    throw new RuntimeException("digit_sum fixture 4: (1000,) -> 1");
}
echo "digit_sum: 4 fixtures passed\n";
