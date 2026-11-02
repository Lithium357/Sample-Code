<?php
declare(strict_types=1);
// Is happy.
// PHP 8.x CLI; php FILE.php
// Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
// Run this file independently; failures exit nonzero.

function is_happy(int $v_n): int {
    $v_steps = 0;
    while ($v_steps < 100) {
        if ($v_n == 1) {
            return 1;
        }
        $v_total = 0;
        while ($v_n > 0) {
            $v_digit = ($v_n % 10);
            $v_total = ($v_total + ($v_digit * $v_digit));
            $v_n = intdiv($v_n, 10);
        }
        $v_n = $v_total;
        $v_steps = ($v_steps + 1);
    }
    return 0;
}

if (is_happy(1) !== 1) {
    throw new RuntimeException("is_happy fixture 1: (1,) -> 1");
}
if (is_happy(19) !== 1) {
    throw new RuntimeException("is_happy fixture 2: (19,) -> 1");
}
if (is_happy(2) !== 0) {
    throw new RuntimeException("is_happy fixture 3: (2,) -> 0");
}
if (is_happy(0) !== 0) {
    throw new RuntimeException("is_happy fixture 4: (0,) -> 0");
}
echo "is_happy: 4 fixtures passed\n";
