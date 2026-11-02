// Is armstrong.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn is_armstrong(mut v_n: i64) -> i64 {
    let mut v_digit: i64 = 0;
    let mut v_digits: i64 = 0;
    let mut v_exponent: i64 = 0;
    let mut v_product: i64 = 0;
    let mut v_remaining: i64 = 0;
    let mut v_total: i64 = 0;
    v_digits = 1;
    v_remaining = v_n;
    while v_remaining >= 10 {
        v_digits = (v_digits + 1);
        v_remaining = (v_remaining / 10);
    }
    v_total = 0;
    v_remaining = v_n;
    while v_remaining > 0 {
        v_digit = (v_remaining % 10);
        v_product = 1;
        v_exponent = 0;
        while v_exponent < v_digits {
            v_product = (v_product * v_digit);
            v_exponent = (v_exponent + 1);
        }
        v_total = (v_total + v_product);
        v_remaining = (v_remaining / 10);
    }
    if v_total == v_n {
        return 1;
    }
    return 0;
}

fn main() {
    assert_eq!(is_armstrong(0), 1, "is_armstrong fixture 1: (0,) -> 1");
    assert_eq!(is_armstrong(153), 1, "is_armstrong fixture 2: (153,) -> 1");
    assert_eq!(is_armstrong(9474), 1, "is_armstrong fixture 3: (9474,) -> 1");
    assert_eq!(is_armstrong(154), 0, "is_armstrong fixture 4: (154,) -> 0");
    println!("is_armstrong: 4 fixtures passed");
}
