<?php
declare(strict_types=1);
// Integer log.
// PHP 8.x CLI; php FILE.php
// Contract: n >= 1; base >= 2; returns floor(log_base(n)).
// Run this file independently; failures exit nonzero.

function integer_log(int $v_n, int $v_base): int {
    $v_exponent = 0;
    while ($v_n >= $v_base) {
        $v_n = intdiv($v_n, $v_base);
        $v_exponent = ($v_exponent + 1);
    }
    return $v_exponent;
}

if (integer_log(1, 2) !== 0) {
    throw new RuntimeException("integer_log fixture 1: (1, 2) -> 0");
}
if (integer_log(8, 2) !== 3) {
    throw new RuntimeException("integer_log fixture 2: (8, 2) -> 3");
}
if (integer_log(99, 10) !== 1) {
    throw new RuntimeException("integer_log fixture 3: (99, 10) -> 1");
}
if (integer_log(100, 10) !== 2) {
    throw new RuntimeException("integer_log fixture 4: (100, 10) -> 2");
}
echo "integer_log: 4 fixtures passed\n";
