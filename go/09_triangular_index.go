// Triangular index.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func triangular_index(v_n int64) int64 {
	var v_index int64
	var v_total int64
	v_total = 0
	v_index = 0
	for v_total < v_n {
		v_index = (v_index + 1)
		v_total = (v_total + v_index)
	}
	if v_total == v_n {
		return v_index
	}
	return (-1)
}

func main() {
	if got := triangular_index(0); got != 0 {
		panic(fmt.Sprintf("triangular_index fixture 1: (0,) -> 0; got %d", got))
	}
	if got := triangular_index(1); got != 1 {
		panic(fmt.Sprintf("triangular_index fixture 2: (1,) -> 1; got %d", got))
	}
	if got := triangular_index(15); got != 5 {
		panic(fmt.Sprintf("triangular_index fixture 3: (15,) -> 5; got %d", got))
	}
	if got := triangular_index(14); got != -1 {
		panic(fmt.Sprintf("triangular_index fixture 4: (14,) -> -1; got %d", got))
	}
	fmt.Println("triangular_index: 4 fixtures passed")
}
