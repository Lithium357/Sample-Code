// Gcd.
// Go 1.20+; go run FILE.go
// Contract: a,b >= 0; gcd(0,0) is defined as 0.
// Run this file independently; failures exit nonzero.

package main

import "fmt"

func gcd(v_a int64, v_b int64) int64 {
	var v_remainder int64
	for v_b != 0 {
		v_remainder = (v_a % v_b)
		v_a = v_b
		v_b = v_remainder
	}
	return v_a
}

func main() {
	if got := gcd(48, 18); got != 6 {
		panic(fmt.Sprintf("gcd fixture 1: (48, 18) -> 6; got %d", got))
	}
	if got := gcd(0, 7); got != 7 {
		panic(fmt.Sprintf("gcd fixture 2: (0, 7) -> 7; got %d", got))
	}
	if got := gcd(7, 0); got != 7 {
		panic(fmt.Sprintf("gcd fixture 3: (7, 0) -> 7; got %d", got))
	}
	if got := gcd(0, 0); got != 0 {
		panic(fmt.Sprintf("gcd fixture 4: (0, 0) -> 0; got %d", got))
	}
	if got := gcd(35, 64); got != 1 {
		panic(fmt.Sprintf("gcd fixture 5: (35, 64) -> 1; got %d", got))
	}
	maximum := int64(9223372036854775807)
	for _, test := range [][3]int64{
		{maximum, maximum, maximum}, {maximum, 0, maximum},
		{maximum, maximum - 1, 1}, {3000000000, 2000000000, 1000000000},
		{832040, 514229, 1},
	} {
		if gcd(test[0], test[1]) != test[2] {
			panic("gcd boundary fixture")
		}
	}
	// Independent reference: enumerate common divisors, not another Euclid loop.
	for a := int64(0); a <= 32; a++ {
		for b := int64(0); b <= 32; b++ {
			var expected int64
			for divisor := int64(1); divisor <= a || divisor <= b; divisor++ {
				if a%divisor == 0 && b%divisor == 0 {
					expected = divisor
				}
			}
			if got := gcd(a, b); got != expected {
				panic(fmt.Sprintf("gcd oracle (%d,%d): expected %d, got %d", a, b, expected, got))
			}
		}
	}
	fmt.Println("gcd: 10 fixed fixtures and 1089 divisor-oracle pairs passed")
}
