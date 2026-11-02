// Largest prime factor.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: n >= 1; returns 1 for the empty factorization of 1.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn largest_prime_factor(mut v_n: i64) -> i64 {
    let mut v_divisor: i64 = 0;
    let mut v_largest: i64 = 0;
    v_largest = 1;
    v_divisor = 2;
    while v_divisor <= (v_n / v_divisor) {
        while (v_n % v_divisor) == 0 {
            v_largest = v_divisor;
            v_n = (v_n / v_divisor);
        }
        v_divisor = (v_divisor + 1);
    }
    if v_n > 1 {
        v_largest = v_n;
    }
    return v_largest;
}

fn main() {
    assert_eq!(largest_prime_factor(1), 1, "largest_prime_factor fixture 1: (1,) -> 1");
    assert_eq!(largest_prime_factor(12), 3, "largest_prime_factor fixture 2: (12,) -> 3");
    assert_eq!(largest_prime_factor(49), 7, "largest_prime_factor fixture 3: (49,) -> 7");
    assert_eq!(largest_prime_factor(97), 97, "largest_prime_factor fixture 4: (97,) -> 97");
    println!("largest_prime_factor: 4 fixtures passed");
}
