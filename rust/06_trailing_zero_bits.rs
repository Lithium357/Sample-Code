// Trailing zero bits.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn trailing_zero_bits(mut v_n: i64) -> i64 {
    let mut v_count: i64 = 0;
    if v_n == 0 {
        return (-1);
    }
    v_count = 0;
    while (v_n % 2) == 0 {
        v_count = (v_count + 1);
        v_n = (v_n / 2);
    }
    return v_count;
}

fn main() {
    assert_eq!(trailing_zero_bits(0), -1, "trailing_zero_bits fixture 1: (0,) -> -1");
    assert_eq!(trailing_zero_bits(1), 0, "trailing_zero_bits fixture 2: (1,) -> 0");
    assert_eq!(trailing_zero_bits(40), 3, "trailing_zero_bits fixture 3: (40,) -> 3");
    assert_eq!(trailing_zero_bits(64), 6, "trailing_zero_bits fixture 4: (64,) -> 6");
    println!("trailing_zero_bits: 4 fixtures passed");
}
