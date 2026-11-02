<?php
declare(strict_types=1);
// Trailing zero bits.
// PHP 8.x CLI; php FILE.php
// Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
// Run this file independently; failures exit nonzero.

function trailing_zero_bits(int $v_n): int {
    if ($v_n == 0) {
        return (-1);
    }
    $v_count = 0;
    while (($v_n % 2) == 0) {
        $v_count = ($v_count + 1);
        $v_n = intdiv($v_n, 2);
    }
    return $v_count;
}

if (trailing_zero_bits(0) !== -1) {
    throw new RuntimeException("trailing_zero_bits fixture 1: (0,) -> -1");
}
if (trailing_zero_bits(1) !== 0) {
    throw new RuntimeException("trailing_zero_bits fixture 2: (1,) -> 0");
}
if (trailing_zero_bits(40) !== 3) {
    throw new RuntimeException("trailing_zero_bits fixture 3: (40,) -> 3");
}
if (trailing_zero_bits(64) !== 6) {
    throw new RuntimeException("trailing_zero_bits fixture 4: (64,) -> 6");
}
echo "trailing_zero_bits: 4 fixtures passed\n";
