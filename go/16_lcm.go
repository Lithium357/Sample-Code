// Lcm.
// Go 1.20+; go run FILE.go
// Contract: a,b >= 0; zero arguments produce 0.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func lcm(v_a int64, v_b int64) int64 {
	var v_remainder int64
	var v_x int64
	var v_y int64
	if v_a == 0 {
		return 0
	}
	if v_b == 0 {
		return 0
	}
	v_x = v_a
	v_y = v_b
	for v_y != 0 {
		v_remainder = (v_x % v_y)
		v_x = v_y
		v_y = v_remainder
	}
	return ((v_a / v_x) * v_b)
}

func main() {
	if got := lcm(12, 18); got != 36 {
		panic(fmt.Sprintf("lcm fixture 1: (12, 18) -> 36; got %d", got))
	}
	if got := lcm(0, 7); got != 0 {
		panic(fmt.Sprintf("lcm fixture 2: (0, 7) -> 0; got %d", got))
	}
	if got := lcm(7, 0); got != 0 {
		panic(fmt.Sprintf("lcm fixture 3: (7, 0) -> 0; got %d", got))
	}
	if got := lcm(5, 7); got != 35 {
		panic(fmt.Sprintf("lcm fixture 4: (5, 7) -> 35; got %d", got))
	}
	if got := lcm(9, 9); got != 9 {
		panic(fmt.Sprintf("lcm fixture 5: (9, 9) -> 9; got %d", got))
	}
	fmt.Println("lcm: 5 fixtures passed")
}
