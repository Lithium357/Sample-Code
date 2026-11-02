// Modular power.
// Go 1.20+; go run FILE.go
// Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func modular_power(v_base int64, v_exponent int64, v_modulus int64) int64 {
	var v_result int64
	v_result = (1 % v_modulus)
	v_base = (v_base % v_modulus)
	for v_exponent > 0 {
		if (v_exponent % 2) == 1 {
			v_result = ((v_result * v_base) % v_modulus)
		}
		v_exponent = (v_exponent / 2)
		v_base = ((v_base * v_base) % v_modulus)
	}
	return v_result
}

func main() {
	if got := modular_power(2, 10, 1000); got != 24 {
		panic(fmt.Sprintf("modular_power fixture 1: (2, 10, 1000) -> 24; got %d", got))
	}
	if got := modular_power(7, 0, 1); got != 0 {
		panic(fmt.Sprintf("modular_power fixture 2: (7, 0, 1) -> 0; got %d", got))
	}
	if got := modular_power(3, 4, 7); got != 4 {
		panic(fmt.Sprintf("modular_power fixture 3: (3, 4, 7) -> 4; got %d", got))
	}
	if got := modular_power(5, 3, 13); got != 8 {
		panic(fmt.Sprintf("modular_power fixture 4: (5, 3, 13) -> 8; got %d", got))
	}
	fmt.Println("modular_power: 4 fixtures passed")
}
