<?php
declare(strict_types=1);
// Discrete log.
// PHP 8.x CLI; php FILE.php
// Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
// Run this file independently; failures exit nonzero.

function discrete_log(int $v_base, int $v_target, int $v_modulus): int {
    $v_value = (1 % $v_modulus);
    $v_exponent = 0;
    while ($v_exponent < $v_modulus) {
        if ($v_value == $v_target) {
            return $v_exponent;
        }
        $v_value = (($v_value * $v_base) % $v_modulus);
        $v_exponent = ($v_exponent + 1);
    }
    return (-1);
}

if (discrete_log(2, 1, 7) !== 0) {
    throw new RuntimeException("discrete_log fixture 1: (2, 1, 7) -> 0");
}
if (discrete_log(2, 4, 7) !== 2) {
    throw new RuntimeException("discrete_log fixture 2: (2, 4, 7) -> 2");
}
if (discrete_log(2, 3, 7) !== -1) {
    throw new RuntimeException("discrete_log fixture 3: (2, 3, 7) -> -1");
}
if (discrete_log(3, 5, 7) !== 5) {
    throw new RuntimeException("discrete_log fixture 4: (3, 5, 7) -> 5");
}
echo "discrete_log: 4 fixtures passed\n";
