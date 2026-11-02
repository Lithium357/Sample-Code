<?php
declare(strict_types=1);
// Pell.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function pell(int $v_n): int {
    $v_previous = 0;
    $v_current = 1;
    $v_index = 0;
    while ($v_index < $v_n) {
        $v_following = ((2 * $v_current) + $v_previous);
        $v_previous = $v_current;
        $v_current = $v_following;
        $v_index = ($v_index + 1);
    }
    return $v_previous;
}

if (pell(0) !== 0) {
    throw new RuntimeException("pell fixture 1: (0,) -> 0");
}
if (pell(1) !== 1) {
    throw new RuntimeException("pell fixture 2: (1,) -> 1");
}
if (pell(5) !== 29) {
    throw new RuntimeException("pell fixture 3: (5,) -> 29");
}
if (pell(10) !== 2378) {
    throw new RuntimeException("pell fixture 4: (10,) -> 2378");
}
echo "pell: 4 fixtures passed\n";
