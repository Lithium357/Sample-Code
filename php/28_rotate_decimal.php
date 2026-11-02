<?php
declare(strict_types=1);
// Rotate decimal.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function rotate_decimal(int $v_n): int {
    if ($v_n < 10) {
        return $v_n;
    }
    $v_scale = 1;
    $v_remaining = $v_n;
    while ($v_remaining >= 10) {
        $v_scale = ($v_scale * 10);
        $v_remaining = intdiv($v_remaining, 10);
    }
    return ((($v_n % 10) * $v_scale) + intdiv($v_n, 10));
}

if (rotate_decimal(0) !== 0) {
    throw new RuntimeException("rotate_decimal fixture 1: (0,) -> 0");
}
if (rotate_decimal(7) !== 7) {
    throw new RuntimeException("rotate_decimal fixture 2: (7,) -> 7");
}
if (rotate_decimal(1234) !== 4123) {
    throw new RuntimeException("rotate_decimal fixture 3: (1234,) -> 4123");
}
if (rotate_decimal(120) !== 12) {
    throw new RuntimeException("rotate_decimal fixture 4: (120,) -> 12");
}
echo "rotate_decimal: 4 fixtures passed\n";
