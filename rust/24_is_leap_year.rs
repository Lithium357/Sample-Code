// Is leap year.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: year >= 1; proleptic Gregorian calendar.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn is_leap_year(mut v_year: i64) -> i64 {
    if (v_year % 400) == 0 {
        return 1;
    }
    if (v_year % 100) == 0 {
        return 0;
    }
    if (v_year % 4) == 0 {
        return 1;
    }
    return 0;
}

fn main() {
    assert_eq!(is_leap_year(1900), 0, "is_leap_year fixture 1: (1900,) -> 0");
    assert_eq!(is_leap_year(2000), 1, "is_leap_year fixture 2: (2000,) -> 1");
    assert_eq!(is_leap_year(2024), 1, "is_leap_year fixture 3: (2024,) -> 1");
    assert_eq!(is_leap_year(2023), 0, "is_leap_year fixture 4: (2023,) -> 0");
    println!("is_leap_year: 4 fixtures passed");
}
