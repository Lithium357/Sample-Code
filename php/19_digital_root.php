<?php
declare(strict_types=1);
// Digital root.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function digital_root(int $v_n): int {
    while ($v_n >= 10) {
        $v_total = 0;
        while ($v_n > 0) {
            $v_total = ($v_total + ($v_n % 10));
            $v_n = intdiv($v_n, 10);
        }
        $v_n = $v_total;
    }
    return $v_n;
}

if (digital_root(0) !== 0) {
    throw new RuntimeException("digital_root fixture 1: (0,) -> 0");
}
if (digital_root(999) !== 9) {
    throw new RuntimeException("digital_root fixture 2: (999,) -> 9");
}
if (digital_root(12345) !== 6) {
    throw new RuntimeException("digital_root fixture 3: (12345,) -> 6");
}
if (digital_root(8) !== 8) {
    throw new RuntimeException("digital_root fixture 4: (8,) -> 8");
}
echo "digital_root: 4 fixtures passed\n";
