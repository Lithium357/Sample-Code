// Modular inverse.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: a >= 0; modulus > 1; returns -1 when no inverse exists.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn modular_inverse(mut v_a: i64, mut v_modulus: i64) -> i64 {
    let mut v_candidate: i64 = 0;
    v_candidate = 1;
    while v_candidate < v_modulus {
        if ((v_a * v_candidate) % v_modulus) == 1 {
            return v_candidate;
        }
        v_candidate = (v_candidate + 1);
    }
    return (-1);
}

fn main() {
    assert_eq!(modular_inverse(3, 7), 5, "modular_inverse fixture 1: (3, 7) -> 5");
    assert_eq!(modular_inverse(2, 4), -1, "modular_inverse fixture 2: (2, 4) -> -1");
    assert_eq!(modular_inverse(1, 5), 1, "modular_inverse fixture 3: (1, 5) -> 1");
    assert_eq!(modular_inverse(7, 11), 8, "modular_inverse fixture 4: (7, 11) -> 8");
    println!("modular_inverse: 4 fixtures passed");
}
