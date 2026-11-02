<?php
declare(strict_types=1);
// Binomial.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function binomial(int $v_n, int $v_k): int {
    if ($v_k > $v_n) {
        return 0;
    }
    if ($v_k > ($v_n - $v_k)) {
        $v_k = ($v_n - $v_k);
    }
    $v_result = 1;
    $v_index = 1;
    while ($v_index <= $v_k) {
        $v_result = intdiv(($v_result * (($v_n - $v_k) + $v_index)), $v_index);
        $v_index = ($v_index + 1);
    }
    return $v_result;
}

if (binomial(5, 2) !== 10) {
    throw new RuntimeException("binomial fixture 1: (5, 2) -> 10");
}
if (binomial(0, 0) !== 1) {
    throw new RuntimeException("binomial fixture 2: (0, 0) -> 1");
}
if (binomial(6, 7) !== 0) {
    throw new RuntimeException("binomial fixture 3: (6, 7) -> 0");
}
if (binomial(10, 5) !== 252) {
    throw new RuntimeException("binomial fixture 4: (10, 5) -> 252");
}
echo "binomial: 4 fixtures passed\n";
