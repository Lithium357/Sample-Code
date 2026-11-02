// Power.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn power(mut v_base: i64, mut v_exponent: i64) -> i64 {
    let mut v_result: i64 = 0;
    v_result = 1;
    while v_exponent > 0 {
        if (v_exponent % 2) == 1 {
            v_result = (v_result * v_base);
        }
        v_exponent = (v_exponent / 2);
        if v_exponent > 0 {
            v_base = (v_base * v_base);
        }
    }
    return v_result;
}

fn main() {
    assert_eq!(power(0, 0), 1, "power fixture 1: (0, 0) -> 1");
    assert_eq!(power(2, 10), 1024, "power fixture 2: (2, 10) -> 1024");
    assert_eq!(power(3, 5), 243, "power fixture 3: (3, 5) -> 243");
    assert_eq!(power(7, 1), 7, "power fixture 4: (7, 1) -> 7");
    println!("power: 4 fixtures passed");
}
