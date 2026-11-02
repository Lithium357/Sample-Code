// Next power of two.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn next_power_of_two(mut v_n: i64) -> i64 {
    let mut v_result: i64 = 0;
    v_result = 1;
    while v_result < v_n {
        v_result = (v_result * 2);
    }
    return v_result;
}

fn main() {
    assert_eq!(next_power_of_two(0), 1, "next_power_of_two fixture 1: (0,) -> 1");
    assert_eq!(next_power_of_two(1), 1, "next_power_of_two fixture 2: (1,) -> 1");
    assert_eq!(next_power_of_two(9), 16, "next_power_of_two fixture 3: (9,) -> 16");
    assert_eq!(next_power_of_two(64), 64, "next_power_of_two fixture 4: (64,) -> 64");
    println!("next_power_of_two: 4 fixtures passed");
}
