// Multiply mod.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn multiply_mod(mut v_a: i64, mut v_b: i64, mut v_modulus: i64) -> i64 {
    let mut v_result: i64 = 0;
    v_result = 0;
    v_a = (v_a % v_modulus);
    while v_b > 0 {
        if (v_b % 2) == 1 {
            v_result = ((v_result + v_a) % v_modulus);
        }
        v_a = ((v_a * 2) % v_modulus);
        v_b = (v_b / 2);
    }
    return v_result;
}

fn main() {
    assert_eq!(multiply_mod(12, 13, 7), 2, "multiply_mod fixture 1: (12, 13, 7) -> 2");
    assert_eq!(multiply_mod(0, 9, 3), 0, "multiply_mod fixture 2: (0, 9, 3) -> 0");
    assert_eq!(multiply_mod(123, 456, 97), 22, "multiply_mod fixture 3: (123, 456, 97) -> 22");
    assert_eq!(multiply_mod(5, 9, 1), 0, "multiply_mod fixture 4: (5, 9, 1) -> 0");
    println!("multiply_mod: 4 fixtures passed");
}
