// Nth prime.
// Go 1.20+; go run FILE.go
// Contract: 1 <= index <= 100; trial division is intended for small inputs.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func nth_prime(v_index int64) int64 {
	var v_candidate int64
	var v_count int64
	var v_divisor int64
	var v_prime int64
	v_count = 0
	v_candidate = 1
	for v_count < v_index {
		v_candidate = (v_candidate + 1)
		v_prime = 1
		v_divisor = 2
		for v_divisor <= (v_candidate / v_divisor) {
			if (v_candidate % v_divisor) == 0 {
				v_prime = 0
			}
			v_divisor = (v_divisor + 1)
		}
		v_count = (v_count + v_prime)
	}
	return v_candidate
}

func main() {
	if got := nth_prime(1); got != 2 {
		panic(fmt.Sprintf("nth_prime fixture 1: (1,) -> 2; got %d", got))
	}
	if got := nth_prime(2); got != 3 {
		panic(fmt.Sprintf("nth_prime fixture 2: (2,) -> 3; got %d", got))
	}
	if got := nth_prime(10); got != 29 {
		panic(fmt.Sprintf("nth_prime fixture 3: (10,) -> 29; got %d", got))
	}
	if got := nth_prime(25); got != 97 {
		panic(fmt.Sprintf("nth_prime fixture 4: (25,) -> 97; got %d", got))
	}
	fmt.Println("nth_prime: 4 fixtures passed")
}
