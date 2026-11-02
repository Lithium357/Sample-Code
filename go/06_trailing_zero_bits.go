// Trailing zero bits.
// Go 1.20+; go run FILE.go
// Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func trailing_zero_bits(v_n int64) int64 {
	var v_count int64
	if v_n == 0 {
		return (-1)
	}
	v_count = 0
	for (v_n % 2) == 0 {
		v_count = (v_count + 1)
		v_n = (v_n / 2)
	}
	return v_count
}

func main() {
	if got := trailing_zero_bits(0); got != -1 {
		panic(fmt.Sprintf("trailing_zero_bits fixture 1: (0,) -> -1; got %d", got))
	}
	if got := trailing_zero_bits(1); got != 0 {
		panic(fmt.Sprintf("trailing_zero_bits fixture 2: (1,) -> 0; got %d", got))
	}
	if got := trailing_zero_bits(40); got != 3 {
		panic(fmt.Sprintf("trailing_zero_bits fixture 3: (40,) -> 3; got %d", got))
	}
	if got := trailing_zero_bits(64); got != 6 {
		panic(fmt.Sprintf("trailing_zero_bits fixture 4: (64,) -> 6; got %d", got))
	}
	fmt.Println("trailing_zero_bits: 4 fixtures passed")
}
