// Is leap year.
// Go 1.20+; go run FILE.go
// Contract: year >= 1; proleptic Gregorian calendar.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func is_leap_year(v_year int64) int64 {
	if (v_year % 400) == 0 {
		return 1
	}
	if (v_year % 100) == 0 {
		return 0
	}
	if (v_year % 4) == 0 {
		return 1
	}
	return 0
}

func main() {
	if got := is_leap_year(1900); got != 0 {
		panic(fmt.Sprintf("is_leap_year fixture 1: (1900,) -> 0; got %d", got))
	}
	if got := is_leap_year(2000); got != 1 {
		panic(fmt.Sprintf("is_leap_year fixture 2: (2000,) -> 1; got %d", got))
	}
	if got := is_leap_year(2024); got != 1 {
		panic(fmt.Sprintf("is_leap_year fixture 3: (2024,) -> 1; got %d", got))
	}
	if got := is_leap_year(2023); got != 0 {
		panic(fmt.Sprintf("is_leap_year fixture 4: (2023,) -> 0; got %d", got))
	}
	fmt.Println("is_leap_year: 4 fixtures passed")
}
