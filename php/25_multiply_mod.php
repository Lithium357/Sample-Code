<?php
declare(strict_types=1);
// Multiply mod.
// PHP 8.x CLI; php FILE.php
// Contract: a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.
// Run this file independently; failures exit nonzero.

function multiply_mod(int $v_a, int $v_b, int $v_modulus): int {
    $v_result = 0;
    $v_a = ($v_a % $v_modulus);
    while ($v_b > 0) {
        if (($v_b % 2) == 1) {
            $v_result = (($v_result + $v_a) % $v_modulus);
        }
        $v_a = (($v_a * 2) % $v_modulus);
        $v_b = intdiv($v_b, 2);
    }
    return $v_result;
}

if (multiply_mod(12, 13, 7) !== 2) {
    throw new RuntimeException("multiply_mod fixture 1: (12, 13, 7) -> 2");
}
if (multiply_mod(0, 9, 3) !== 0) {
    throw new RuntimeException("multiply_mod fixture 2: (0, 9, 3) -> 0");
}
if (multiply_mod(123, 456, 97) !== 22) {
    throw new RuntimeException("multiply_mod fixture 3: (123, 456, 97) -> 22");
}
if (multiply_mod(5, 9, 1) !== 0) {
    throw new RuntimeException("multiply_mod fixture 4: (5, 9, 1) -> 0");
}
echo "multiply_mod: 4 fixtures passed\n";
