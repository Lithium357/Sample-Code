// Ceil div.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: numerator >= 0; denominator > 0.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn ceil_div(mut v_numerator: i64, mut v_denominator: i64) -> i64 {
    let mut v_quotient: i64 = 0;
    v_quotient = (v_numerator / v_denominator);
    if (v_numerator % v_denominator) != 0 {
        v_quotient = (v_quotient + 1);
    }
    return v_quotient;
}

fn main() {
    assert_eq!(ceil_div(0, 3), 0, "ceil_div fixture 1: (0, 3) -> 0");
    assert_eq!(ceil_div(10, 3), 4, "ceil_div fixture 2: (10, 3) -> 4");
    assert_eq!(ceil_div(12, 3), 4, "ceil_div fixture 3: (12, 3) -> 4");
    assert_eq!(ceil_div(1, 9), 1, "ceil_div fixture 4: (1, 9) -> 1");
    println!("ceil_div: 4 fixtures passed");
}
