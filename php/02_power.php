<?php
declare(strict_types=1);
// Power.
// PHP 8.x CLI; php FILE.php
// Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
// Run this file independently; failures exit nonzero.

function power(int $v_base, int $v_exponent): int {
    $v_result = 1;
    while ($v_exponent > 0) {
        if (($v_exponent % 2) == 1) {
            $v_result = ($v_result * $v_base);
        }
        $v_exponent = intdiv($v_exponent, 2);
        if ($v_exponent > 0) {
            $v_base = ($v_base * $v_base);
        }
    }
    return $v_result;
}

if (power(0, 0) !== 1) {
    throw new RuntimeException("power fixture 1: (0, 0) -> 1");
}
if (power(2, 10) !== 1024) {
    throw new RuntimeException("power fixture 2: (2, 10) -> 1024");
}
if (power(3, 5) !== 243) {
    throw new RuntimeException("power fixture 3: (3, 5) -> 243");
}
if (power(7, 1) !== 7) {
    throw new RuntimeException("power fixture 4: (7, 1) -> 7");
}
echo "power: 4 fixtures passed\n";
