<?php
declare(strict_types=1);
// Factorial.
// PHP 8.x CLI; php FILE.php
// Contract: 0 <= n <= 12; larger values exceed CMD signed 32-bit arithmetic.
// Run this file independently; failures exit nonzero.

function factorial(int $v_n): int {
    $v_result = 1;
    $v_factor = 2;
    while ($v_factor <= $v_n) {
        $v_result = ($v_result * $v_factor);
        $v_factor = ($v_factor + 1);
    }
    return $v_result;
}

if (factorial(0) !== 1) {
    throw new RuntimeException("factorial fixture 1: (0,) -> 1");
}
if (factorial(1) !== 1) {
    throw new RuntimeException("factorial fixture 2: (1,) -> 1");
}
if (factorial(5) !== 120) {
    throw new RuntimeException("factorial fixture 3: (5,) -> 120");
}
if (factorial(10) !== 3628800) {
    throw new RuntimeException("factorial fixture 4: (10,) -> 3628800");
}
echo "factorial: 4 fixtures passed\n";
