// Lucas.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func lucas(v_n int64) int64 {
	var v_current int64
	var v_following int64
	var v_index int64
	var v_previous int64
	v_previous = 2
	v_current = 1
	v_index = 0
	for v_index < v_n {
		v_following = (v_previous + v_current)
		v_previous = v_current
		v_current = v_following
		v_index = (v_index + 1)
	}
	return v_previous
}

func main() {
	if got := lucas(0); got != 2 {
		panic(fmt.Sprintf("lucas fixture 1: (0,) -> 2; got %d", got))
	}
	if got := lucas(1); got != 1 {
		panic(fmt.Sprintf("lucas fixture 2: (1,) -> 1; got %d", got))
	}
	if got := lucas(5); got != 11 {
		panic(fmt.Sprintf("lucas fixture 3: (5,) -> 11; got %d", got))
	}
	if got := lucas(10); got != 123 {
		panic(fmt.Sprintf("lucas fixture 4: (10,) -> 123; got %d", got))
	}
	fmt.Println("lucas: 4 fixtures passed")
}
