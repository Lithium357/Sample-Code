// Rotate decimal.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn rotate_decimal(mut v_n: i64) -> i64 {
    let mut v_remaining: i64 = 0;
    let mut v_scale: i64 = 0;
    if v_n < 10 {
        return v_n;
    }
    v_scale = 1;
    v_remaining = v_n;
    while v_remaining >= 10 {
        v_scale = (v_scale * 10);
        v_remaining = (v_remaining / 10);
    }
    return (((v_n % 10) * v_scale) + (v_n / 10));
}

fn main() {
    assert_eq!(rotate_decimal(0), 0, "rotate_decimal fixture 1: (0,) -> 0");
    assert_eq!(rotate_decimal(7), 7, "rotate_decimal fixture 2: (7,) -> 7");
    assert_eq!(rotate_decimal(1234), 4123, "rotate_decimal fixture 3: (1234,) -> 4123");
    assert_eq!(rotate_decimal(120), 12, "rotate_decimal fixture 4: (120,) -> 12");
    println!("rotate_decimal: 4 fixtures passed");
}
