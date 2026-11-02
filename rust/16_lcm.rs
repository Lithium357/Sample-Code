// Lcm.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: a,b >= 0; zero arguments produce 0.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn lcm(mut v_a: i64, mut v_b: i64) -> i64 {
    let mut v_remainder: i64 = 0;
    let mut v_x: i64 = 0;
    let mut v_y: i64 = 0;
    if v_a == 0 {
        return 0;
    }
    if v_b == 0 {
        return 0;
    }
    v_x = v_a;
    v_y = v_b;
    while v_y != 0 {
        v_remainder = (v_x % v_y);
        v_x = v_y;
        v_y = v_remainder;
    }
    return ((v_a / v_x) * v_b);
}

fn main() {
    assert_eq!(lcm(12, 18), 36, "lcm fixture 1: (12, 18) -> 36");
    assert_eq!(lcm(0, 7), 0, "lcm fixture 2: (0, 7) -> 0");
    assert_eq!(lcm(7, 0), 0, "lcm fixture 3: (7, 0) -> 0");
    assert_eq!(lcm(5, 7), 35, "lcm fixture 4: (5, 7) -> 35");
    assert_eq!(lcm(9, 9), 9, "lcm fixture 5: (9, 9) -> 9");
    println!("lcm: 5 fixtures passed");
}
