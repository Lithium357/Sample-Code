<?php
declare(strict_types=1);
// Rectangle count.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function rectangle_count(int $v_width, int $v_height): int {
    $v_horizontal = intdiv(($v_width * ($v_width + 1)), 2);
    $v_vertical = intdiv(($v_height * ($v_height + 1)), 2);
    return ($v_horizontal * $v_vertical);
}

if (rectangle_count(0, 4) !== 0) {
    throw new RuntimeException("rectangle_count fixture 1: (0, 4) -> 0");
}
if (rectangle_count(1, 1) !== 1) {
    throw new RuntimeException("rectangle_count fixture 2: (1, 1) -> 1");
}
if (rectangle_count(2, 3) !== 18) {
    throw new RuntimeException("rectangle_count fixture 3: (2, 3) -> 18");
}
if (rectangle_count(4, 4) !== 100) {
    throw new RuntimeException("rectangle_count fixture 4: (4, 4) -> 100");
}
echo "rectangle_count: 4 fixtures passed\n";
