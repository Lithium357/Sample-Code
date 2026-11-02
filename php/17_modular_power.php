<?php
declare(strict_types=1);
// Modular power.
// PHP 8.x CLI; php FILE.php
// Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
// Run this file independently; failures exit nonzero.

function modular_power(int $v_base, int $v_exponent, int $v_modulus): int {
    $v_result = (1 % $v_modulus);
    $v_base = ($v_base % $v_modulus);
    while ($v_exponent > 0) {
        if (($v_exponent % 2) == 1) {
            $v_result = (($v_result * $v_base) % $v_modulus);
        }
        $v_exponent = intdiv($v_exponent, 2);
        $v_base = (($v_base * $v_base) % $v_modulus);
    }
    return $v_result;
}

if (modular_power(2, 10, 1000) !== 24) {
    throw new RuntimeException("modular_power fixture 1: (2, 10, 1000) -> 24");
}
if (modular_power(7, 0, 1) !== 0) {
    throw new RuntimeException("modular_power fixture 2: (7, 0, 1) -> 0");
}
if (modular_power(3, 4, 7) !== 4) {
    throw new RuntimeException("modular_power fixture 3: (3, 4, 7) -> 4");
}
if (modular_power(5, 3, 13) !== 8) {
    throw new RuntimeException("modular_power fixture 4: (5, 3, 13) -> 8");
}
echo "modular_power: 4 fixtures passed\n";
