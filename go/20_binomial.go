// Binomial.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func binomial(v_n int64, v_k int64) int64 {
	var v_index int64
	var v_result int64
	if v_k > v_n {
		return 0
	}
	if v_k > (v_n - v_k) {
		v_k = (v_n - v_k)
	}
	v_result = 1
	v_index = 1
	for v_index <= v_k {
		v_result = ((v_result * ((v_n - v_k) + v_index)) / v_index)
		v_index = (v_index + 1)
	}
	return v_result
}

func main() {
	if got := binomial(5, 2); got != 10 {
		panic(fmt.Sprintf("binomial fixture 1: (5, 2) -> 10; got %d", got))
	}
	if got := binomial(0, 0); got != 1 {
		panic(fmt.Sprintf("binomial fixture 2: (0, 0) -> 1; got %d", got))
	}
	if got := binomial(6, 7); got != 0 {
		panic(fmt.Sprintf("binomial fixture 3: (6, 7) -> 0; got %d", got))
	}
	if got := binomial(10, 5); got != 252 {
		panic(fmt.Sprintf("binomial fixture 4: (10, 5) -> 252; got %d", got))
	}
	fmt.Println("binomial: 4 fixtures passed")
}
