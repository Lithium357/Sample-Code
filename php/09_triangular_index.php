<?php
declare(strict_types=1);
// Triangular index.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function triangular_index(int $v_n): int {
    $v_total = 0;
    $v_index = 0;
    while ($v_total < $v_n) {
        $v_index = ($v_index + 1);
        $v_total = ($v_total + $v_index);
    }
    if ($v_total == $v_n) {
        return $v_index;
    }
    return (-1);
}

if (triangular_index(0) !== 0) {
    throw new RuntimeException("triangular_index fixture 1: (0,) -> 0");
}
if (triangular_index(1) !== 1) {
    throw new RuntimeException("triangular_index fixture 2: (1,) -> 1");
}
if (triangular_index(15) !== 5) {
    throw new RuntimeException("triangular_index fixture 3: (15,) -> 5");
}
if (triangular_index(14) !== -1) {
    throw new RuntimeException("triangular_index fixture 4: (14,) -> -1");
}
echo "triangular_index: 4 fixtures passed\n";
