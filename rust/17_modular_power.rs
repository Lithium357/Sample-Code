// Modular power.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn modular_power(mut v_base: i64, mut v_exponent: i64, mut v_modulus: i64) -> i64 {
    let mut v_result: i64 = 0;
    v_result = (1 % v_modulus);
    v_base = (v_base % v_modulus);
    while v_exponent > 0 {
        if (v_exponent % 2) == 1 {
            v_result = ((v_result * v_base) % v_modulus);
        }
        v_exponent = (v_exponent / 2);
        v_base = ((v_base * v_base) % v_modulus);
    }
    return v_result;
}

fn main() {
    assert_eq!(modular_power(2, 10, 1000), 24, "modular_power fixture 1: (2, 10, 1000) -> 24");
    assert_eq!(modular_power(7, 0, 1), 0, "modular_power fixture 2: (7, 0, 1) -> 0");
    assert_eq!(modular_power(3, 4, 7), 4, "modular_power fixture 3: (3, 4, 7) -> 4");
    assert_eq!(modular_power(5, 3, 13), 8, "modular_power fixture 4: (5, 3, 13) -> 8");
    println!("modular_power: 4 fixtures passed");
}
