// Rotate decimal.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func rotate_decimal(v_n int64) int64 {
	var v_remaining int64
	var v_scale int64
	if v_n < 10 {
		return v_n
	}
	v_scale = 1
	v_remaining = v_n
	for v_remaining >= 10 {
		v_scale = (v_scale * 10)
		v_remaining = (v_remaining / 10)
	}
	return (((v_n % 10) * v_scale) + (v_n / 10))
}

func main() {
	if got := rotate_decimal(0); got != 0 {
		panic(fmt.Sprintf("rotate_decimal fixture 1: (0,) -> 0; got %d", got))
	}
	if got := rotate_decimal(7); got != 7 {
		panic(fmt.Sprintf("rotate_decimal fixture 2: (7,) -> 7; got %d", got))
	}
	if got := rotate_decimal(1234); got != 4123 {
		panic(fmt.Sprintf("rotate_decimal fixture 3: (1234,) -> 4123; got %d", got))
	}
	if got := rotate_decimal(120); got != 12 {
		panic(fmt.Sprintf("rotate_decimal fixture 4: (120,) -> 12; got %d", got))
	}
	fmt.Println("rotate_decimal: 4 fixtures passed")
}
