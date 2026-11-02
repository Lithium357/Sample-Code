// Gcd.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: a,b >= 0; gcd(0,0) is defined as 0.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn gcd(mut v_a: i64, mut v_b: i64) -> i64 {
    let mut v_remainder: i64 = 0;
    while v_b != 0 {
        v_remainder = (v_a % v_b);
        v_a = v_b;
        v_b = v_remainder;
    }
    return v_a;
}

fn main() {
    assert_eq!(gcd(48, 18), 6, "gcd fixture 1: (48, 18) -> 6");
    assert_eq!(gcd(0, 7), 7, "gcd fixture 2: (0, 7) -> 7");
    assert_eq!(gcd(7, 0), 7, "gcd fixture 3: (7, 0) -> 7");
    assert_eq!(gcd(0, 0), 0, "gcd fixture 4: (0, 0) -> 0");
    assert_eq!(gcd(35, 64), 1, "gcd fixture 5: (35, 64) -> 1");
    println!("gcd: 5 fixtures passed");
}
