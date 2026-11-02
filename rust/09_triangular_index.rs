// Triangular index.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn triangular_index(mut v_n: i64) -> i64 {
    let mut v_index: i64 = 0;
    let mut v_total: i64 = 0;
    v_total = 0;
    v_index = 0;
    while v_total < v_n {
        v_index = (v_index + 1);
        v_total = (v_total + v_index);
    }
    if v_total == v_n {
        return v_index;
    }
    return (-1);
}

fn main() {
    assert_eq!(triangular_index(0), 0, "triangular_index fixture 1: (0,) -> 0");
    assert_eq!(triangular_index(1), 1, "triangular_index fixture 2: (1,) -> 1");
    assert_eq!(triangular_index(15), 5, "triangular_index fixture 3: (15,) -> 5");
    assert_eq!(triangular_index(14), -1, "triangular_index fixture 4: (14,) -> -1");
    println!("triangular_index: 4 fixtures passed");
}
