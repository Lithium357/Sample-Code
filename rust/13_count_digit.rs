// Count digit.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn count_digit(mut v_n: i64, mut v_target: i64) -> i64 {
    let mut v_count: i64 = 0;
    if v_n == 0 {
        if v_target == 0 {
            return 1;
        }
        return 0;
    }
    v_count = 0;
    while v_n > 0 {
        if (v_n % 10) == v_target {
            v_count = (v_count + 1);
        }
        v_n = (v_n / 10);
    }
    return v_count;
}

fn main() {
    assert_eq!(count_digit(0, 0), 1, "count_digit fixture 1: (0, 0) -> 1");
    assert_eq!(count_digit(0, 1), 0, "count_digit fixture 2: (0, 1) -> 0");
    assert_eq!(count_digit(1001, 0), 2, "count_digit fixture 3: (1001, 0) -> 2");
    assert_eq!(count_digit(777, 7), 3, "count_digit fixture 4: (777, 7) -> 3");
    println!("count_digit: 4 fixtures passed");
}
