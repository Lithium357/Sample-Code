// Ceil div.
// Go 1.20+; go run FILE.go
// Contract: numerator >= 0; denominator > 0.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func ceil_div(v_numerator int64, v_denominator int64) int64 {
	var v_quotient int64
	v_quotient = (v_numerator / v_denominator)
	if (v_numerator % v_denominator) != 0 {
		v_quotient = (v_quotient + 1)
	}
	return v_quotient
}

func main() {
	if got := ceil_div(0, 3); got != 0 {
		panic(fmt.Sprintf("ceil_div fixture 1: (0, 3) -> 0; got %d", got))
	}
	if got := ceil_div(10, 3); got != 4 {
		panic(fmt.Sprintf("ceil_div fixture 2: (10, 3) -> 4; got %d", got))
	}
	if got := ceil_div(12, 3); got != 4 {
		panic(fmt.Sprintf("ceil_div fixture 3: (12, 3) -> 4; got %d", got))
	}
	if got := ceil_div(1, 9); got != 1 {
		panic(fmt.Sprintf("ceil_div fixture 4: (1, 9) -> 1; got %d", got))
	}
	fmt.Println("ceil_div: 4 fixtures passed")
}
