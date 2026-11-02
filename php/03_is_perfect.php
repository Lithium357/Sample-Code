<?php
declare(strict_types=1);
// Is perfect.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function is_perfect(int $v_n): int {
    $v_total = 0;
    $v_divisor = 1;
    while ($v_divisor < $v_n) {
        if (($v_n % $v_divisor) == 0) {
            $v_total = ($v_total + $v_divisor);
        }
        $v_divisor = ($v_divisor + 1);
    }
    if ($v_total == $v_n) {
        if ($v_n > 0) {
            return 1;
        }
    }
    return 0;
}

if (is_perfect(0) !== 0) {
    throw new RuntimeException("is_perfect fixture 1: (0,) -> 0");
}
if (is_perfect(1) !== 0) {
    throw new RuntimeException("is_perfect fixture 2: (1,) -> 0");
}
if (is_perfect(6) !== 1) {
    throw new RuntimeException("is_perfect fixture 3: (6,) -> 1");
}
if (is_perfect(28) !== 1) {
    throw new RuntimeException("is_perfect fixture 4: (28,) -> 1");
}
if (is_perfect(12) !== 0) {
    throw new RuntimeException("is_perfect fixture 5: (12,) -> 0");
}
echo "is_perfect: 5 fixtures passed\n";
