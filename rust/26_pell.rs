// Pell.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn pell(mut v_n: i64) -> i64 {
    let mut v_current: i64 = 0;
    let mut v_following: i64 = 0;
    let mut v_index: i64 = 0;
    let mut v_previous: i64 = 0;
    v_previous = 0;
    v_current = 1;
    v_index = 0;
    while v_index < v_n {
        v_following = ((2 * v_current) + v_previous);
        v_previous = v_current;
        v_current = v_following;
        v_index = (v_index + 1);
    }
    return v_previous;
}

fn main() {
    assert_eq!(pell(0), 0, "pell fixture 1: (0,) -> 0");
    assert_eq!(pell(1), 1, "pell fixture 2: (1,) -> 1");
    assert_eq!(pell(5), 29, "pell fixture 3: (5,) -> 29");
    assert_eq!(pell(10), 2378, "pell fixture 4: (10,) -> 2378");
    println!("pell: 4 fixtures passed");
}
