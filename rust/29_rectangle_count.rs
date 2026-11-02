// Rectangle count.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn rectangle_count(mut v_width: i64, mut v_height: i64) -> i64 {
    let mut v_horizontal: i64 = 0;
    let mut v_vertical: i64 = 0;
    v_horizontal = ((v_width * (v_width + 1)) / 2);
    v_vertical = ((v_height * (v_height + 1)) / 2);
    return (v_horizontal * v_vertical);
}

fn main() {
    assert_eq!(rectangle_count(0, 4), 0, "rectangle_count fixture 1: (0, 4) -> 0");
    assert_eq!(rectangle_count(1, 1), 1, "rectangle_count fixture 2: (1, 1) -> 1");
    assert_eq!(rectangle_count(2, 3), 18, "rectangle_count fixture 3: (2, 3) -> 18");
    assert_eq!(rectangle_count(4, 4), 100, "rectangle_count fixture 4: (4, 4) -> 100");
    println!("rectangle_count: 4 fixtures passed");
}
