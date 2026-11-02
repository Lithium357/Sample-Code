// Greedy coin count.
// Go 1.20+; go run FILE.go
// Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func greedy_coin_count(v_amount int64) int64 {
	var v_count int64
	v_count = (v_amount / 25)
	v_amount = (v_amount % 25)
	v_count = (v_count + (v_amount / 10))
	v_amount = (v_amount % 10)
	v_count = (v_count + (v_amount / 5))
	v_amount = (v_amount % 5)
	return (v_count + v_amount)
}

func main() {
	if got := greedy_coin_count(0); got != 0 {
		panic(fmt.Sprintf("greedy_coin_count fixture 1: (0,) -> 0; got %d", got))
	}
	if got := greedy_coin_count(30); got != 2 {
		panic(fmt.Sprintf("greedy_coin_count fixture 2: (30,) -> 2; got %d", got))
	}
	if got := greedy_coin_count(41); got != 4 {
		panic(fmt.Sprintf("greedy_coin_count fixture 3: (41,) -> 4; got %d", got))
	}
	if got := greedy_coin_count(99); got != 9 {
		panic(fmt.Sprintf("greedy_coin_count fixture 4: (99,) -> 9; got %d", got))
	}
	fmt.Println("greedy_coin_count: 4 fixtures passed")
}
