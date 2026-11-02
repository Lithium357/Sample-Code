// Is armstrong.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func is_armstrong(v_n int64) int64 {
	var v_digit int64
	var v_digits int64
	var v_exponent int64
	var v_product int64
	var v_remaining int64
	var v_total int64
	v_digits = 1
	v_remaining = v_n
	for v_remaining >= 10 {
		v_digits = (v_digits + 1)
		v_remaining = (v_remaining / 10)
	}
	v_total = 0
	v_remaining = v_n
	for v_remaining > 0 {
		v_digit = (v_remaining % 10)
		v_product = 1
		v_exponent = 0
		for v_exponent < v_digits {
			v_product = (v_product * v_digit)
			v_exponent = (v_exponent + 1)
		}
		v_total = (v_total + v_product)
		v_remaining = (v_remaining / 10)
	}
	if v_total == v_n {
		return 1
	}
	return 0
}

func main() {
	if got := is_armstrong(0); got != 1 {
		panic(fmt.Sprintf("is_armstrong fixture 1: (0,) -> 1; got %d", got))
	}
	if got := is_armstrong(153); got != 1 {
		panic(fmt.Sprintf("is_armstrong fixture 2: (153,) -> 1; got %d", got))
	}
	if got := is_armstrong(9474); got != 1 {
		panic(fmt.Sprintf("is_armstrong fixture 3: (9474,) -> 1; got %d", got))
	}
	if got := is_armstrong(154); got != 0 {
		panic(fmt.Sprintf("is_armstrong fixture 4: (154,) -> 0; got %d", got))
	}
	fmt.Println("is_armstrong: 4 fixtures passed")
}
