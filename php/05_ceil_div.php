<?php
declare(strict_types=1);
// Ceil div.
// PHP 8.x CLI; php FILE.php
// Contract: numerator >= 0; denominator > 0.
// Run this file independently; failures exit nonzero.

function ceil_div(int $v_numerator, int $v_denominator): int {
    $v_quotient = intdiv($v_numerator, $v_denominator);
    if (($v_numerator % $v_denominator) != 0) {
        $v_quotient = ($v_quotient + 1);
    }
    return $v_quotient;
}

if (ceil_div(0, 3) !== 0) {
    throw new RuntimeException("ceil_div fixture 1: (0, 3) -> 0");
}
if (ceil_div(10, 3) !== 4) {
    throw new RuntimeException("ceil_div fixture 2: (10, 3) -> 4");
}
if (ceil_div(12, 3) !== 4) {
    throw new RuntimeException("ceil_div fixture 3: (12, 3) -> 4");
}
if (ceil_div(1, 9) !== 1) {
    throw new RuntimeException("ceil_div fixture 4: (1, 9) -> 1");
}
echo "ceil_div: 4 fixtures passed\n";
