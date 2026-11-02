<?php
declare(strict_types=1);
// Count digit.
// PHP 8.x CLI; php FILE.php
// Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
// Run this file independently; failures exit nonzero.

function count_digit(int $v_n, int $v_target): int {
    if ($v_n == 0) {
        if ($v_target == 0) {
            return 1;
        }
        return 0;
    }
    $v_count = 0;
    while ($v_n > 0) {
        if (($v_n % 10) == $v_target) {
            $v_count = ($v_count + 1);
        }
        $v_n = intdiv($v_n, 10);
    }
    return $v_count;
}

if (count_digit(0, 0) !== 1) {
    throw new RuntimeException("count_digit fixture 1: (0, 0) -> 1");
}
if (count_digit(0, 1) !== 0) {
    throw new RuntimeException("count_digit fixture 2: (0, 1) -> 0");
}
if (count_digit(1001, 0) !== 2) {
    throw new RuntimeException("count_digit fixture 3: (1001, 0) -> 2");
}
if (count_digit(777, 7) !== 3) {
    throw new RuntimeException("count_digit fixture 4: (777, 7) -> 3");
}
echo "count_digit: 4 fixtures passed\n";
