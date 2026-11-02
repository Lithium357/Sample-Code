// Greedy coin count.
// Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo
// Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
// Run this file independently; failures exit nonzero.

#[allow(unused_mut, unused_assignments)]
fn greedy_coin_count(mut v_amount: i64) -> i64 {
    let mut v_count: i64 = 0;
    v_count = (v_amount / 25);
    v_amount = (v_amount % 25);
    v_count = (v_count + (v_amount / 10));
    v_amount = (v_amount % 10);
    v_count = (v_count + (v_amount / 5));
    v_amount = (v_amount % 5);
    return (v_count + v_amount);
}

fn main() {
    assert_eq!(greedy_coin_count(0), 0, "greedy_coin_count fixture 1: (0,) -> 0");
    assert_eq!(greedy_coin_count(30), 2, "greedy_coin_count fixture 2: (30,) -> 2");
    assert_eq!(greedy_coin_count(41), 4, "greedy_coin_count fixture 3: (41,) -> 4");
    assert_eq!(greedy_coin_count(99), 9, "greedy_coin_count fixture 4: (99,) -> 9");
    println!("greedy_coin_count: 4 fixtures passed");
}
