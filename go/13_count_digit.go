// Count digit.
// Go 1.20+; go run FILE.go
// Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func count_digit(v_n int64, v_target int64) int64 {
	var v_count int64
	if v_n == 0 {
		if v_target == 0 {
			return 1
		}
		return 0
	}
	v_count = 0
	for v_n > 0 {
		if (v_n % 10) == v_target {
			v_count = (v_count + 1)
		}
		v_n = (v_n / 10)
	}
	return v_count
}

func main() {
	if got := count_digit(0, 0); got != 1 {
		panic(fmt.Sprintf("count_digit fixture 1: (0, 0) -> 1; got %d", got))
	}
	if got := count_digit(0, 1); got != 0 {
		panic(fmt.Sprintf("count_digit fixture 2: (0, 1) -> 0; got %d", got))
	}
	if got := count_digit(1001, 0); got != 2 {
		panic(fmt.Sprintf("count_digit fixture 3: (1001, 0) -> 2; got %d", got))
	}
	if got := count_digit(777, 7); got != 3 {
		panic(fmt.Sprintf("count_digit fixture 4: (777, 7) -> 3; got %d", got))
	}
	fmt.Println("count_digit: 4 fixtures passed")
}
