// Largest prime factor.
// Go 1.20+; go run FILE.go
// Contract: n >= 1; returns 1 for the empty factorization of 1.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func largest_prime_factor(v_n int64) int64 {
	var v_divisor int64
	var v_largest int64
	v_largest = 1
	v_divisor = 2
	for v_divisor <= (v_n / v_divisor) {
		for (v_n % v_divisor) == 0 {
			v_largest = v_divisor
			v_n = (v_n / v_divisor)
		}
		v_divisor = (v_divisor + 1)
	}
	if v_n > 1 {
		v_largest = v_n
	}
	return v_largest
}

func main() {
	if got := largest_prime_factor(1); got != 1 {
		panic(fmt.Sprintf("largest_prime_factor fixture 1: (1,) -> 1; got %d", got))
	}
	if got := largest_prime_factor(12); got != 3 {
		panic(fmt.Sprintf("largest_prime_factor fixture 2: (12,) -> 3; got %d", got))
	}
	if got := largest_prime_factor(49); got != 7 {
		panic(fmt.Sprintf("largest_prime_factor fixture 3: (49,) -> 7; got %d", got))
	}
	if got := largest_prime_factor(97); got != 97 {
		panic(fmt.Sprintf("largest_prime_factor fixture 4: (97,) -> 97; got %d", got))
	}
	fmt.Println("largest_prime_factor: 4 fixtures passed")
}
