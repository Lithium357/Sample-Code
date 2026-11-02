// Binomial.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn binomial(mut v_n: i64, mut v_k: i64) -> i64 {
    let mut v_index: i64 = 0;
    let mut v_result: i64 = 0;
    if v_k > v_n {
        return 0;
    }
    if v_k > (v_n - v_k) {
        v_k = (v_n - v_k);
    }
    v_result = 1;
    v_index = 1;
    while v_index <= v_k {
        v_result = ((v_result * ((v_n - v_k) + v_index)) / v_index);
        v_index = (v_index + 1);
    }
    return v_result;
}

fn main() {
    assert_eq!(binomial(5, 2), 10, "binomial fixture 1: (5, 2) -> 10");
    assert_eq!(binomial(0, 0), 1, "binomial fixture 2: (0, 0) -> 1");
    assert_eq!(binomial(6, 7), 0, "binomial fixture 3: (6, 7) -> 0");
    assert_eq!(binomial(10, 5), 252, "binomial fixture 4: (10, 5) -> 252");
    println!("binomial: 4 fixtures passed");
}
