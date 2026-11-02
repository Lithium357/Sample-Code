// Is perfect.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func is_perfect(v_n int64) int64 {
	var v_divisor int64
	var v_total int64
	v_total = 0
	v_divisor = 1
	for v_divisor < v_n {
		if (v_n % v_divisor) == 0 {
			v_total = (v_total + v_divisor)
		}
		v_divisor = (v_divisor + 1)
	}
	if v_total == v_n {
		if v_n > 0 {
			return 1
		}
	}
	return 0
}

func main() {
	if got := is_perfect(0); got != 0 {
		panic(fmt.Sprintf("is_perfect fixture 1: (0,) -> 0; got %d", got))
	}
	if got := is_perfect(1); got != 0 {
		panic(fmt.Sprintf("is_perfect fixture 2: (1,) -> 0; got %d", got))
	}
	if got := is_perfect(6); got != 1 {
		panic(fmt.Sprintf("is_perfect fixture 3: (6,) -> 1; got %d", got))
	}
	if got := is_perfect(28); got != 1 {
		panic(fmt.Sprintf("is_perfect fixture 4: (28,) -> 1; got %d", got))
	}
	if got := is_perfect(12); got != 0 {
		panic(fmt.Sprintf("is_perfect fixture 5: (12,) -> 0; got %d", got))
	}
	fmt.Println("is_perfect: 5 fixtures passed")
}
