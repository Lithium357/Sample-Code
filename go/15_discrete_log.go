// Discrete log.
// Go 1.20+; go run FILE.go
// Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func discrete_log(v_base int64, v_target int64, v_modulus int64) int64 {
	var v_exponent int64
	var v_value int64
	v_value = (1 % v_modulus)
	v_exponent = 0
	for v_exponent < v_modulus {
		if v_value == v_target {
			return v_exponent
		}
		v_value = ((v_value * v_base) % v_modulus)
		v_exponent = (v_exponent + 1)
	}
	return (-1)
}

func main() {
	if got := discrete_log(2, 1, 7); got != 0 {
		panic(fmt.Sprintf("discrete_log fixture 1: (2, 1, 7) -> 0; got %d", got))
	}
	if got := discrete_log(2, 4, 7); got != 2 {
		panic(fmt.Sprintf("discrete_log fixture 2: (2, 4, 7) -> 2; got %d", got))
	}
	if got := discrete_log(2, 3, 7); got != -1 {
		panic(fmt.Sprintf("discrete_log fixture 3: (2, 3, 7) -> -1; got %d", got))
	}
	if got := discrete_log(3, 5, 7); got != 5 {
		panic(fmt.Sprintf("discrete_log fixture 4: (3, 5, 7) -> 5; got %d", got))
	}
	fmt.Println("discrete_log: 4 fixtures passed")
}
