// Is palindrome.
// Go 1.20+; go run FILE.go
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func is_palindrome(v_n int64) int64 {
	var v_original int64
	var v_reversed_value int64
	v_original = v_n
	v_reversed_value = 0
	for v_n > 0 {
		v_reversed_value = ((v_reversed_value * 10) + (v_n % 10))
		v_n = (v_n / 10)
	}
	if v_reversed_value == v_original {
		return 1
	}
	return 0
}

func main() {
	if got := is_palindrome(0); got != 1 {
		panic(fmt.Sprintf("is_palindrome fixture 1: (0,) -> 1; got %d", got))
	}
	if got := is_palindrome(1221); got != 1 {
		panic(fmt.Sprintf("is_palindrome fixture 2: (1221,) -> 1; got %d", got))
	}
	if got := is_palindrome(123); got != 0 {
		panic(fmt.Sprintf("is_palindrome fixture 3: (123,) -> 0; got %d", got))
	}
	if got := is_palindrome(101); got != 1 {
		panic(fmt.Sprintf("is_palindrome fixture 4: (101,) -> 1; got %d", got))
	}
	fmt.Println("is_palindrome: 4 fixtures passed")
}
