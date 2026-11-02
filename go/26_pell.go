// Pell.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func pell(v_n int64) int64 {
	var v_current int64
	var v_following int64
	var v_index int64
	var v_previous int64
	v_previous = 0
	v_current = 1
	v_index = 0
	for v_index < v_n {
		v_following = ((2 * v_current) + v_previous)
		v_previous = v_current
		v_current = v_following
		v_index = (v_index + 1)
	}
	return v_previous
}

func main() {
	if got := pell(0); got != 0 {
		panic(fmt.Sprintf("pell fixture 1: (0,) -> 0; got %d", got))
	}
	if got := pell(1); got != 1 {
		panic(fmt.Sprintf("pell fixture 2: (1,) -> 1; got %d", got))
	}
	if got := pell(5); got != 29 {
		panic(fmt.Sprintf("pell fixture 3: (5,) -> 29; got %d", got))
	}
	if got := pell(10); got != 2378 {
		panic(fmt.Sprintf("pell fixture 4: (10,) -> 2378; got %d", got))
	}
	fmt.Println("pell: 4 fixtures passed")
}
