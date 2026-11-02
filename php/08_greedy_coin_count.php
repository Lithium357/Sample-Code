<?php
declare(strict_types=1);
// Greedy coin count.
// PHP 8.x CLI; php FILE.php
// Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
// Run this file independently; failures exit nonzero.

function greedy_coin_count(int $v_amount): int {
    $v_count = intdiv($v_amount, 25);
    $v_amount = ($v_amount % 25);
    $v_count = ($v_count + intdiv($v_amount, 10));
    $v_amount = ($v_amount % 10);
    $v_count = ($v_count + intdiv($v_amount, 5));
    $v_amount = ($v_amount % 5);
    return ($v_count + $v_amount);
}

if (greedy_coin_count(0) !== 0) {
    throw new RuntimeException("greedy_coin_count fixture 1: (0,) -> 0");
}
if (greedy_coin_count(30) !== 2) {
    throw new RuntimeException("greedy_coin_count fixture 2: (30,) -> 2");
}
if (greedy_coin_count(41) !== 4) {
    throw new RuntimeException("greedy_coin_count fixture 3: (41,) -> 4");
}
if (greedy_coin_count(99) !== 9) {
    throw new RuntimeException("greedy_coin_count fixture 4: (99,) -> 9");
}
echo "greedy_coin_count: 4 fixtures passed\n";
