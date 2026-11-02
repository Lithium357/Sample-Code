// Power.
// Go 1.20+; go run FILE.go
// Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func power(v_base int64, v_exponent int64) int64 {
	var v_result int64
	v_result = 1
	for v_exponent > 0 {
		if (v_exponent % 2) == 1 {
			v_result = (v_result * v_base)
		}
		v_exponent = (v_exponent / 2)
		if v_exponent > 0 {
			v_base = (v_base * v_base)
		}
	}
	return v_result
}

func main() {
	if got := power(0, 0); got != 1 {
		panic(fmt.Sprintf("power fixture 1: (0, 0) -> 1; got %d", got))
	}
	if got := power(2, 10); got != 1024 {
		panic(fmt.Sprintf("power fixture 2: (2, 10) -> 1024; got %d", got))
	}
	if got := power(3, 5); got != 243 {
		panic(fmt.Sprintf("power fixture 3: (3, 5) -> 243; got %d", got))
	}
	if got := power(7, 1); got != 7 {
		panic(fmt.Sprintf("power fixture 4: (7, 1) -> 7; got %d", got))
	}
	fmt.Println("power: 4 fixtures passed")
}
