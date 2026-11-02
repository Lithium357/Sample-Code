# Greedy coin count.
# Nim 2.x; nim c -r FILE.nim
# Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
# Run this file independently; failures exit nonzero.

proc greedy_coin_count(v_amount_arg: int64): int64 =
    var v_amount = v_amount_arg
    var v_count: int64 = 0
    v_count = (v_amount div 25)
    v_amount = (v_amount mod 25)
    v_count = (v_count + (v_amount div 10))
    v_amount = (v_amount mod 10)
    v_count = (v_count + (v_amount div 5))
    v_amount = (v_amount mod 5)
    return (v_count + v_amount)

when isMainModule:
    doAssert greedy_coin_count(0) == 0, "greedy_coin_count fixture 1: (0,) -> 0"
    doAssert greedy_coin_count(30) == 2, "greedy_coin_count fixture 2: (30,) -> 2"
    doAssert greedy_coin_count(41) == 4, "greedy_coin_count fixture 3: (41,) -> 4"
    doAssert greedy_coin_count(99) == 9, "greedy_coin_count fixture 4: (99,) -> 9"
    echo "greedy_coin_count: 4 fixtures passed"
