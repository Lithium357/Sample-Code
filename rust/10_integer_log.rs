// Integer log.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: n >= 1; base >= 2; returns floor(log_base(n)).
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn integer_log(mut v_n: i64, mut v_base: i64) -> i64 {
    let mut v_exponent: i64 = 0;
    v_exponent = 0;
    while v_n >= v_base {
        v_n = (v_n / v_base);
        v_exponent = (v_exponent + 1);
    }
    return v_exponent;
}

fn main() {
    assert_eq!(integer_log(1, 2), 0, "integer_log fixture 1: (1, 2) -> 0");
    assert_eq!(integer_log(8, 2), 3, "integer_log fixture 2: (8, 2) -> 3");
    assert_eq!(integer_log(99, 10), 1, "integer_log fixture 3: (99, 10) -> 1");
    assert_eq!(integer_log(100, 10), 2, "integer_log fixture 4: (100, 10) -> 2");
    println!("integer_log: 4 fixtures passed");
}
