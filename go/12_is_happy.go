// Is happy.
// Go 1.20+; go run FILE.go
// Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func is_happy(v_n int64) int64 {
	var v_digit int64
	var v_steps int64
	var v_total int64
	v_steps = 0
	for v_steps < 100 {
		if v_n == 1 {
			return 1
		}
		v_total = 0
		for v_n > 0 {
			v_digit = (v_n % 10)
			v_total = (v_total + (v_digit * v_digit))
			v_n = (v_n / 10)
		}
		v_n = v_total
		v_steps = (v_steps + 1)
	}
	return 0
}

func main() {
	if got := is_happy(1); got != 1 {
		panic(fmt.Sprintf("is_happy fixture 1: (1,) -> 1; got %d", got))
	}
	if got := is_happy(19); got != 1 {
		panic(fmt.Sprintf("is_happy fixture 2: (19,) -> 1; got %d", got))
	}
	if got := is_happy(2); got != 0 {
		panic(fmt.Sprintf("is_happy fixture 3: (2,) -> 0; got %d", got))
	}
	if got := is_happy(0); got != 0 {
		panic(fmt.Sprintf("is_happy fixture 4: (0,) -> 0; got %d", got))
	}
	fmt.Println("is_happy: 4 fixtures passed")
}
