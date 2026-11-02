// Integer log.
// Go 1.20+; go run FILE.go
// Contract: n >= 1; base >= 2; returns floor(log_base(n)).
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func integer_log(v_n int64, v_base int64) int64 {
	var v_exponent int64
	v_exponent = 0
	for v_n >= v_base {
		v_n = (v_n / v_base)
		v_exponent = (v_exponent + 1)
	}
	return v_exponent
}

func main() {
	if got := integer_log(1, 2); got != 0 {
		panic(fmt.Sprintf("integer_log fixture 1: (1, 2) -> 0; got %d", got))
	}
	if got := integer_log(8, 2); got != 3 {
		panic(fmt.Sprintf("integer_log fixture 2: (8, 2) -> 3; got %d", got))
	}
	if got := integer_log(99, 10); got != 1 {
		panic(fmt.Sprintf("integer_log fixture 3: (99, 10) -> 1; got %d", got))
	}
	if got := integer_log(100, 10); got != 2 {
		panic(fmt.Sprintf("integer_log fixture 4: (100, 10) -> 2; got %d", got))
	}
	fmt.Println("integer_log: 4 fixtures passed")
}
