// Nth prime.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: 1 <= index <= 100; trial division is intended for small inputs.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn nth_prime(mut v_index: i64) -> i64 {
    let mut v_candidate: i64 = 0;
    let mut v_count: i64 = 0;
    let mut v_divisor: i64 = 0;
    let mut v_prime: i64 = 0;
    v_count = 0;
    v_candidate = 1;
    while v_count < v_index {
        v_candidate = (v_candidate + 1);
        v_prime = 1;
        v_divisor = 2;
        while v_divisor <= (v_candidate / v_divisor) {
            if (v_candidate % v_divisor) == 0 {
                v_prime = 0;
            }
            v_divisor = (v_divisor + 1);
        }
        v_count = (v_count + v_prime);
    }
    return v_candidate;
}

fn main() {
    assert_eq!(nth_prime(1), 2, "nth_prime fixture 1: (1,) -> 2");
    assert_eq!(nth_prime(2), 3, "nth_prime fixture 2: (2,) -> 3");
    assert_eq!(nth_prime(10), 29, "nth_prime fixture 3: (10,) -> 29");
    assert_eq!(nth_prime(25), 97, "nth_prime fixture 4: (25,) -> 97");
    println!("nth_prime: 4 fixtures passed");
}
