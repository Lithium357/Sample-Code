<?php
declare(strict_types=1);
// Lucas.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function lucas(int $v_n): int {
    $v_previous = 2;
    $v_current = 1;
    $v_index = 0;
    while ($v_index < $v_n) {
        $v_following = ($v_previous + $v_current);
        $v_previous = $v_current;
        $v_current = $v_following;
        $v_index = ($v_index + 1);
    }
    return $v_previous;
}

if (lucas(0) !== 2) {
    throw new RuntimeException("lucas fixture 1: (0,) -> 2");
}
if (lucas(1) !== 1) {
    throw new RuntimeException("lucas fixture 2: (1,) -> 1");
}
if (lucas(5) !== 11) {
    throw new RuntimeException("lucas fixture 3: (5,) -> 11");
}
if (lucas(10) !== 123) {
    throw new RuntimeException("lucas fixture 4: (10,) -> 123");
}
echo "lucas: 4 fixtures passed\n";
