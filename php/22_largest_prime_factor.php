<?php
declare(strict_types=1);
// Largest prime factor.
// PHP 8.x CLI; php FILE.php
// Contract: n >= 1; returns 1 for the empty factorization of 1.
// Run this file independently; failures exit nonzero.

function largest_prime_factor(int $v_n): int {
    $v_largest = 1;
    $v_divisor = 2;
    while ($v_divisor <= intdiv($v_n, $v_divisor)) {
        while (($v_n % $v_divisor) == 0) {
            $v_largest = $v_divisor;
            $v_n = intdiv($v_n, $v_divisor);
        }
        $v_divisor = ($v_divisor + 1);
    }
    if ($v_n > 1) {
        $v_largest = $v_n;
    }
    return $v_largest;
}

if (largest_prime_factor(1) !== 1) {
    throw new RuntimeException("largest_prime_factor fixture 1: (1,) -> 1");
}
if (largest_prime_factor(12) !== 3) {
    throw new RuntimeException("largest_prime_factor fixture 2: (12,) -> 3");
}
if (largest_prime_factor(49) !== 7) {
    throw new RuntimeException("largest_prime_factor fixture 3: (49,) -> 7");
}
if (largest_prime_factor(97) !== 97) {
    throw new RuntimeException("largest_prime_factor fixture 4: (97,) -> 97");
}
echo "largest_prime_factor: 4 fixtures passed\n";
