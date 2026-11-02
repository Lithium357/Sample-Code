// Digital root.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn digital_root(mut v_n: i64) -> i64 {
    let mut v_total: i64 = 0;
    while v_n >= 10 {
        v_total = 0;
        while v_n > 0 {
            v_total = (v_total + (v_n % 10));
            v_n = (v_n / 10);
        }
        v_n = v_total;
    }
    return v_n;
}

fn main() {
    assert_eq!(digital_root(0), 0, "digital_root fixture 1: (0,) -> 0");
    assert_eq!(digital_root(999), 9, "digital_root fixture 2: (999,) -> 9");
    assert_eq!(digital_root(12345), 6, "digital_root fixture 3: (12345,) -> 6");
    assert_eq!(digital_root(8), 8, "digital_root fixture 4: (8,) -> 8");
    println!("digital_root: 4 fixtures passed");
}
