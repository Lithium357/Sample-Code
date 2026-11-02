<?php
declare(strict_types=1);
// Modular inverse.
// PHP 8.x CLI; php FILE.php
// Contract: a >= 0; modulus > 1; returns -1 when no inverse exists.
// Run this file independently; failures exit nonzero.

function modular_inverse(int $v_a, int $v_modulus): int {
    $v_candidate = 1;
    while ($v_candidate < $v_modulus) {
        if ((($v_a * $v_candidate) % $v_modulus) == 1) {
            return $v_candidate;
        }
        $v_candidate = ($v_candidate + 1);
    }
    return (-1);
}

if (modular_inverse(3, 7) !== 5) {
    throw new RuntimeException("modular_inverse fixture 1: (3, 7) -> 5");
}
if (modular_inverse(2, 4) !== -1) {
    throw new RuntimeException("modular_inverse fixture 2: (2, 4) -> -1");
}
if (modular_inverse(1, 5) !== 1) {
    throw new RuntimeException("modular_inverse fixture 3: (1, 5) -> 1");
}
if (modular_inverse(7, 11) !== 8) {
    throw new RuntimeException("modular_inverse fixture 4: (7, 11) -> 8");
}
echo "modular_inverse: 4 fixtures passed\n";
