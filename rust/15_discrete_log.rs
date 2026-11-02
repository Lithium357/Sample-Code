// Discrete log.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn discrete_log(mut v_base: i64, mut v_target: i64, mut v_modulus: i64) -> i64 {
    let mut v_exponent: i64 = 0;
    let mut v_value: i64 = 0;
    v_value = (1 % v_modulus);
    v_exponent = 0;
    while v_exponent < v_modulus {
        if v_value == v_target {
            return v_exponent;
        }
        v_value = ((v_value * v_base) % v_modulus);
        v_exponent = (v_exponent + 1);
    }
    return (-1);
}

fn main() {
    assert_eq!(discrete_log(2, 1, 7), 0, "discrete_log fixture 1: (2, 1, 7) -> 0");
    assert_eq!(discrete_log(2, 4, 7), 2, "discrete_log fixture 2: (2, 4, 7) -> 2");
    assert_eq!(discrete_log(2, 3, 7), -1, "discrete_log fixture 3: (2, 3, 7) -> -1");
    assert_eq!(discrete_log(3, 5, 7), 5, "discrete_log fixture 4: (3, 5, 7) -> 5");
    println!("discrete_log: 4 fixtures passed");
}
