// Digit sum.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn digit_sum(mut v_n: i64) -> i64 {
    let mut v_total: i64 = 0;
    v_total = 0;
    while v_n > 0 {
        v_total = (v_total + (v_n % 10));
        v_n = (v_n / 10);
    }
    return v_total;
}

fn main() {
    assert_eq!(digit_sum(0), 0, "digit_sum fixture 1: (0,) -> 0");
    assert_eq!(digit_sum(12345), 15, "digit_sum fixture 2: (12345,) -> 15");
    assert_eq!(digit_sum(909), 18, "digit_sum fixture 3: (909,) -> 18");
    assert_eq!(digit_sum(1000), 1, "digit_sum fixture 4: (1000,) -> 1");
    println!("digit_sum: 4 fixtures passed");
}
