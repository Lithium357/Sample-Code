// Is happy.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn is_happy(mut v_n: i64) -> i64 {
    let mut v_digit: i64 = 0;
    let mut v_steps: i64 = 0;
    let mut v_total: i64 = 0;
    v_steps = 0;
    while v_steps < 100 {
        if v_n == 1 {
            return 1;
        }
        v_total = 0;
        while v_n > 0 {
            v_digit = (v_n % 10);
            v_total = (v_total + (v_digit * v_digit));
            v_n = (v_n / 10);
        }
        v_n = v_total;
        v_steps = (v_steps + 1);
    }
    return 0;
}

fn main() {
    assert_eq!(is_happy(1), 1, "is_happy fixture 1: (1,) -> 1");
    assert_eq!(is_happy(19), 1, "is_happy fixture 2: (19,) -> 1");
    assert_eq!(is_happy(2), 0, "is_happy fixture 3: (2,) -> 0");
    assert_eq!(is_happy(0), 0, "is_happy fixture 4: (0,) -> 0");
    println!("is_happy: 4 fixtures passed");
}
