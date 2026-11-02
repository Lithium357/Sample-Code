<?php
declare(strict_types=1);
// Lcm.
// PHP 8.x CLI; php FILE.php
// Contract: a,b >= 0; zero arguments produce 0.
// Run this file independently; failures exit nonzero.

function lcm(int $v_a, int $v_b): int {
    if ($v_a == 0) {
        return 0;
    }
    if ($v_b == 0) {
        return 0;
    }
    $v_x = $v_a;
    $v_y = $v_b;
    while ($v_y != 0) {
        $v_remainder = ($v_x % $v_y);
        $v_x = $v_y;
        $v_y = $v_remainder;
    }
    return (intdiv($v_a, $v_x) * $v_b);
}

if (lcm(12, 18) !== 36) {
    throw new RuntimeException("lcm fixture 1: (12, 18) -> 36");
}
if (lcm(0, 7) !== 0) {
    throw new RuntimeException("lcm fixture 2: (0, 7) -> 0");
}
if (lcm(7, 0) !== 0) {
    throw new RuntimeException("lcm fixture 3: (7, 0) -> 0");
}
if (lcm(5, 7) !== 35) {
    throw new RuntimeException("lcm fixture 4: (5, 7) -> 35");
}
if (lcm(9, 9) !== 9) {
    throw new RuntimeException("lcm fixture 5: (9, 9) -> 9");
}
echo "lcm: 5 fixtures passed\n";
