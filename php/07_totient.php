<?php
declare(strict_types=1);
// Totient.
// PHP 8.x CLI; php FILE.php
// Contract: n >= 1.
// Run this file independently; failures exit nonzero.

function totient(int $v_n): int {
    $v_result = $v_n;
    $v_prime = 2;
    $v_remaining = $v_n;
    while ($v_prime <= intdiv($v_remaining, $v_prime)) {
        if (($v_remaining % $v_prime) == 0) {
            while (($v_remaining % $v_prime) == 0) {
                $v_remaining = intdiv($v_remaining, $v_prime);
            }
            $v_result = ($v_result - intdiv($v_result, $v_prime));
        }
        $v_prime = ($v_prime + 1);
    }
    if ($v_remaining > 1) {
        $v_result = ($v_result - intdiv($v_result, $v_remaining));
    }
    return $v_result;
}

if (totient(1) !== 1) {
    throw new RuntimeException("totient fixture 1: (1,) -> 1");
}
if (totient(9) !== 6) {
    throw new RuntimeException("totient fixture 2: (9,) -> 6");
}
if (totient(12) !== 4) {
    throw new RuntimeException("totient fixture 3: (12,) -> 4");
}
if (totient(97) !== 96) {
    throw new RuntimeException("totient fixture 4: (97,) -> 96");
}
echo "totient: 4 fixtures passed\n";
