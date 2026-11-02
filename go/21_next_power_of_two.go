// Next power of two.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func next_power_of_two(v_n int64) int64 {
	var v_result int64
	v_result = 1
	for v_result < v_n {
		v_result = (v_result * 2)
	}
	return v_result
}

func main() {
	if got := next_power_of_two(0); got != 1 {
		panic(fmt.Sprintf("next_power_of_two fixture 1: (0,) -> 1; got %d", got))
	}
	if got := next_power_of_two(1); got != 1 {
		panic(fmt.Sprintf("next_power_of_two fixture 2: (1,) -> 1; got %d", got))
	}
	if got := next_power_of_two(9); got != 16 {
		panic(fmt.Sprintf("next_power_of_two fixture 3: (9,) -> 16; got %d", got))
	}
	if got := next_power_of_two(64); got != 64 {
		panic(fmt.Sprintf("next_power_of_two fixture 4: (64,) -> 64; got %d", got))
	}
	fmt.Println("next_power_of_two: 4 fixtures passed")
}
