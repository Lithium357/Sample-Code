// Lattice paths.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func lattice_paths(v_width int64, v_height int64) int64 {
	var v_index int64
	var v_result int64
	var v_steps int64
	v_steps = (v_width + v_height)
	v_result = 1
	v_index = 1
	for v_index <= v_width {
		v_result = ((v_result * ((v_steps - v_width) + v_index)) / v_index)
		v_index = (v_index + 1)
	}
	return v_result
}

func main() {
	if got := lattice_paths(0, 0); got != 1 {
		panic(fmt.Sprintf("lattice_paths fixture 1: (0, 0) -> 1; got %d", got))
	}
	if got := lattice_paths(2, 2); got != 6 {
		panic(fmt.Sprintf("lattice_paths fixture 2: (2, 2) -> 6; got %d", got))
	}
	if got := lattice_paths(3, 2); got != 10 {
		panic(fmt.Sprintf("lattice_paths fixture 3: (3, 2) -> 10; got %d", got))
	}
	if got := lattice_paths(4, 4); got != 70 {
		panic(fmt.Sprintf("lattice_paths fixture 4: (4, 4) -> 70; got %d", got))
	}
	fmt.Println("lattice_paths: 4 fixtures passed")
}
