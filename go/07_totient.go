// Totient.
// Go 1.20+; go run FILE.go
// Contract: n >= 1.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func totient(v_n int64) int64 {
	var v_prime int64
	var v_remaining int64
	var v_result int64
	v_result = v_n
	v_prime = 2
	v_remaining = v_n
	for v_prime <= (v_remaining / v_prime) {
		if (v_remaining % v_prime) == 0 {
			for (v_remaining % v_prime) == 0 {
				v_remaining = (v_remaining / v_prime)
			}
			v_result = (v_result - (v_result / v_prime))
		}
		v_prime = (v_prime + 1)
	}
	if v_remaining > 1 {
		v_result = (v_result - (v_result / v_remaining))
	}
	return v_result
}

func main() {
	if got := totient(1); got != 1 {
		panic(fmt.Sprintf("totient fixture 1: (1,) -> 1; got %d", got))
	}
	if got := totient(9); got != 6 {
		panic(fmt.Sprintf("totient fixture 2: (9,) -> 6; got %d", got))
	}
	if got := totient(12); got != 4 {
		panic(fmt.Sprintf("totient fixture 3: (12,) -> 4; got %d", got))
	}
	if got := totient(97); got != 96 {
		panic(fmt.Sprintf("totient fixture 4: (97,) -> 96; got %d", got))
	}
	fmt.Println("totient: 4 fixtures passed")
}
