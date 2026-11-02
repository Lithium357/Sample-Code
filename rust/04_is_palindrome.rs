// Is palindrome.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn is_palindrome(mut v_n: i64) -> i64 {
    let mut v_original: i64 = 0;
    let mut v_reversed_value: i64 = 0;
    v_original = v_n;
    v_reversed_value = 0;
    while v_n > 0 {
        v_reversed_value = ((v_reversed_value * 10) + (v_n % 10));
        v_n = (v_n / 10);
    }
    if v_reversed_value == v_original {
        return 1;
    }
    return 0;
}

fn main() {
    assert_eq!(is_palindrome(0), 1, "is_palindrome fixture 1: (0,) -> 1");
    assert_eq!(is_palindrome(1221), 1, "is_palindrome fixture 2: (1221,) -> 1");
    assert_eq!(is_palindrome(123), 0, "is_palindrome fixture 3: (123,) -> 0");
    assert_eq!(is_palindrome(101), 1, "is_palindrome fixture 4: (101,) -> 1");
    println!("is_palindrome: 4 fixtures passed");
}
