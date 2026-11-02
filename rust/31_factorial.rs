// Factorial.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: 0 <= n <= 12; larger values exceed CMD signed 32-bit arithmetic.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn factorial(mut v_n: i64) -> i64 {
    let mut v_factor: i64 = 0;
    let mut v_result: i64 = 0;
    v_result = 1;
    v_factor = 2;
    while v_factor <= v_n {
        v_result = (v_result * v_factor);
        v_factor = (v_factor + 1);
    }
    return v_result;
}

fn main() {
    assert_eq!(factorial(0), 1, "factorial fixture 1: (0,) -> 1");
    assert_eq!(factorial(1), 1, "factorial fixture 2: (1,) -> 1");
    assert_eq!(factorial(5), 120, "factorial fixture 3: (5,) -> 120");
    assert_eq!(factorial(10), 3628800, "factorial fixture 4: (10,) -> 3628800");
    println!("factorial: 4 fixtures passed");
}
