<?php
declare(strict_types=1);
// Gcd.
// PHP 8.x CLI; php FILE.php
// Contract: a,b >= 0; gcd(0,0) is defined as 0.
// Run this file independently; failures exit nonzero.

function gcd(int $v_a, int $v_b): int {
    while ($v_b != 0) {
        $v_remainder = ($v_a % $v_b);
        $v_a = $v_b;
        $v_b = $v_remainder;
    }
    return $v_a;
}

if (gcd(48, 18) !== 6) {
    throw new RuntimeException("gcd fixture 1: (48, 18) -> 6");
}
if (gcd(0, 7) !== 7) {
    throw new RuntimeException("gcd fixture 2: (0, 7) -> 7");
}
if (gcd(7, 0) !== 7) {
    throw new RuntimeException("gcd fixture 3: (7, 0) -> 7");
}
if (gcd(0, 0) !== 0) {
    throw new RuntimeException("gcd fixture 4: (0, 0) -> 0");
}
if (gcd(35, 64) !== 1) {
    throw new RuntimeException("gcd fixture 5: (35, 64) -> 1");
}
echo "gcd: 5 fixtures passed\n";
