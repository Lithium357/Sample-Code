// Totient.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: n >= 1.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn totient(mut v_n: i64) -> i64 {
    let mut v_prime: i64 = 0;
    let mut v_remaining: i64 = 0;
    let mut v_result: i64 = 0;
    v_result = v_n;
    v_prime = 2;
    v_remaining = v_n;
    while v_prime <= (v_remaining / v_prime) {
        if (v_remaining % v_prime) == 0 {
            while (v_remaining % v_prime) == 0 {
                v_remaining = (v_remaining / v_prime);
            }
            v_result = (v_result - (v_result / v_prime));
        }
        v_prime = (v_prime + 1);
    }
    if v_remaining > 1 {
        v_result = (v_result - (v_result / v_remaining));
    }
    return v_result;
}

fn main() {
    assert_eq!(totient(1), 1, "totient fixture 1: (1,) -> 1");
    assert_eq!(totient(9), 6, "totient fixture 2: (9,) -> 6");
    assert_eq!(totient(12), 4, "totient fixture 3: (12,) -> 4");
    assert_eq!(totient(97), 96, "totient fixture 4: (97,) -> 96");
    println!("totient: 4 fixtures passed");
}
