// Lattice paths.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn lattice_paths(mut v_width: i64, mut v_height: i64) -> i64 {
    let mut v_index: i64 = 0;
    let mut v_result: i64 = 0;
    let mut v_steps: i64 = 0;
    v_steps = (v_width + v_height);
    v_result = 1;
    v_index = 1;
    while v_index <= v_width {
        v_result = ((v_result * ((v_steps - v_width) + v_index)) / v_index);
        v_index = (v_index + 1);
    }
    return v_result;
}

fn main() {
    assert_eq!(lattice_paths(0, 0), 1, "lattice_paths fixture 1: (0, 0) -> 1");
    assert_eq!(lattice_paths(2, 2), 6, "lattice_paths fixture 2: (2, 2) -> 6");
    assert_eq!(lattice_paths(3, 2), 10, "lattice_paths fixture 3: (3, 2) -> 10");
    assert_eq!(lattice_paths(4, 4), 70, "lattice_paths fixture 4: (4, 4) -> 70");
    println!("lattice_paths: 4 fixtures passed");
}
