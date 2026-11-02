<?php
declare(strict_types=1);
// Is prime.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function is_prime(int $v_n): int {
    if ($v_n < 2) {
        return 0;
    }
    $v_divisor = 2;
    while ($v_divisor <= intdiv($v_n, $v_divisor)) {
        if (($v_n % $v_divisor) == 0) {
            return 0;
        }
        $v_divisor = ($v_divisor + 1);
    }
    return 1;
}

if (is_prime(0) !== 0) {
    throw new RuntimeException("is_prime fixture 1: (0,) -> 0");
}
if (is_prime(1) !== 0) {
    throw new RuntimeException("is_prime fixture 2: (1,) -> 0");
}
if (is_prime(2) !== 1) {
    throw new RuntimeException("is_prime fixture 3: (2,) -> 1");
}
if (is_prime(49) !== 0) {
    throw new RuntimeException("is_prime fixture 4: (49,) -> 0");
}
if (is_prime(97) !== 1) {
    throw new RuntimeException("is_prime fixture 5: (97,) -> 1");
}
echo "is_prime: 5 fixtures passed\n";
