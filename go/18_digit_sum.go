// Digit sum.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func digit_sum(v_n int64) int64 {
	var v_total int64
	v_total = 0
	for v_n > 0 {
		v_total = (v_total + (v_n % 10))
		v_n = (v_n / 10)
	}
	return v_total
}

func main() {
	if got := digit_sum(0); got != 0 {
		panic(fmt.Sprintf("digit_sum fixture 1: (0,) -> 0; got %d", got))
	}
	if got := digit_sum(12345); got != 15 {
		panic(fmt.Sprintf("digit_sum fixture 2: (12345,) -> 15; got %d", got))
	}
	if got := digit_sum(909); got != 18 {
		panic(fmt.Sprintf("digit_sum fixture 3: (909,) -> 18; got %d", got))
	}
	if got := digit_sum(1000); got != 1 {
		panic(fmt.Sprintf("digit_sum fixture 4: (1000,) -> 1; got %d", got))
	}
	fmt.Println("digit_sum: 4 fixtures passed")
}
