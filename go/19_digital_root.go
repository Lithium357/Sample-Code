// Digital root.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func digital_root(v_n int64) int64 {
	var v_total int64
	for v_n >= 10 {
		v_total = 0
		for v_n > 0 {
			v_total = (v_total + (v_n % 10))
			v_n = (v_n / 10)
		}
		v_n = v_total
	}
	return v_n
}

func main() {
	if got := digital_root(0); got != 0 {
		panic(fmt.Sprintf("digital_root fixture 1: (0,) -> 0; got %d", got))
	}
	if got := digital_root(999); got != 9 {
		panic(fmt.Sprintf("digital_root fixture 2: (999,) -> 9; got %d", got))
	}
	if got := digital_root(12345); got != 6 {
		panic(fmt.Sprintf("digital_root fixture 3: (12345,) -> 6; got %d", got))
	}
	if got := digital_root(8); got != 8 {
		panic(fmt.Sprintf("digital_root fixture 4: (8,) -> 8; got %d", got))
	}
	fmt.Println("digital_root: 4 fixtures passed")
}
