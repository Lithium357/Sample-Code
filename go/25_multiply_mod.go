// Multiply mod.
// Go 1.20+; go run FILE.go
// Contract: a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func multiply_mod(v_a int64, v_b int64, v_modulus int64) int64 {
	var v_result int64
	v_result = 0
	v_a = (v_a % v_modulus)
	for v_b > 0 {
		if (v_b % 2) == 1 {
			v_result = ((v_result + v_a) % v_modulus)
		}
		v_a = ((v_a * 2) % v_modulus)
		v_b = (v_b / 2)
	}
	return v_result
}

func main() {
	if got := multiply_mod(12, 13, 7); got != 2 {
		panic(fmt.Sprintf("multiply_mod fixture 1: (12, 13, 7) -> 2; got %d", got))
	}
	if got := multiply_mod(0, 9, 3); got != 0 {
		panic(fmt.Sprintf("multiply_mod fixture 2: (0, 9, 3) -> 0; got %d", got))
	}
	if got := multiply_mod(123, 456, 97); got != 22 {
		panic(fmt.Sprintf("multiply_mod fixture 3: (123, 456, 97) -> 22; got %d", got))
	}
	if got := multiply_mod(5, 9, 1); got != 0 {
		panic(fmt.Sprintf("multiply_mod fixture 4: (5, 9, 1) -> 0; got %d", got))
	}
	fmt.Println("multiply_mod: 4 fixtures passed")
}
