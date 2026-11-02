<?php
declare(strict_types=1);
// Lattice paths.
// PHP 8.x CLI; php FILE.php
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

function lattice_paths(int $v_width, int $v_height): int {
    $v_steps = ($v_width + $v_height);
    $v_result = 1;
    $v_index = 1;
    while ($v_index <= $v_width) {
        $v_result = intdiv(($v_result * (($v_steps - $v_width) + $v_index)), $v_index);
        $v_index = ($v_index + 1);
    }
    return $v_result;
}

if (lattice_paths(0, 0) !== 1) {
    throw new RuntimeException("lattice_paths fixture 1: (0, 0) -> 1");
}
if (lattice_paths(2, 2) !== 6) {
    throw new RuntimeException("lattice_paths fixture 2: (2, 2) -> 6");
}
if (lattice_paths(3, 2) !== 10) {
    throw new RuntimeException("lattice_paths fixture 3: (3, 2) -> 10");
}
if (lattice_paths(4, 4) !== 70) {
    throw new RuntimeException("lattice_paths fixture 4: (4, 4) -> 70");
}
echo "lattice_paths: 4 fixtures passed\n";
