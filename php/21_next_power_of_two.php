<?php
declare(strict_types=1);
// Next power of two.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function next_power_of_two(int $v_n): int {
    $v_result = 1;
    while ($v_result < $v_n) {
        $v_result = ($v_result * 2);
    }
    return $v_result;
}

if (next_power_of_two(0) !== 1) {
    throw new RuntimeException("next_power_of_two fixture 1: (0,) -> 1");
}
if (next_power_of_two(1) !== 1) {
    throw new RuntimeException("next_power_of_two fixture 2: (1,) -> 1");
}
if (next_power_of_two(9) !== 16) {
    throw new RuntimeException("next_power_of_two fixture 3: (9,) -> 16");
}
if (next_power_of_two(64) !== 64) {
    throw new RuntimeException("next_power_of_two fixture 4: (64,) -> 64");
}
echo "next_power_of_two: 4 fixtures passed\n";
