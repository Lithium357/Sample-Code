<?php
declare(strict_types=1);
// Nth prime.
// PHP 8.x CLI; php FILE.php
// Contract: 1 <= index <= 100; trial division is intended for small inputs.
// Run this file independently; failures exit nonzero.

function nth_prime(int $v_index): int {
    $v_count = 0;
    $v_candidate = 1;
    while ($v_count < $v_index) {
        $v_candidate = ($v_candidate + 1);
        $v_prime = 1;
        $v_divisor = 2;
        while ($v_divisor <= intdiv($v_candidate, $v_divisor)) {
            if (($v_candidate % $v_divisor) == 0) {
                $v_prime = 0;
            }
            $v_divisor = ($v_divisor + 1);
        }
        $v_count = ($v_count + $v_prime);
    }
    return $v_candidate;
}

if (nth_prime(1) !== 2) {
    throw new RuntimeException("nth_prime fixture 1: (1,) -> 2");
}
if (nth_prime(2) !== 3) {
    throw new RuntimeException("nth_prime fixture 2: (2,) -> 3");
}
if (nth_prime(10) !== 29) {
    throw new RuntimeException("nth_prime fixture 3: (10,) -> 29");
}
if (nth_prime(25) !== 97) {
    throw new RuntimeException("nth_prime fixture 4: (25,) -> 97");
}
echo "nth_prime: 4 fixtures passed\n";
