# Greedy coin count.
# Ruby 3.x; ruby FILE.rb
# Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
# Run this file independently; failures exit nonzero.

def greedy_coin_count(v_amount)
    v_count = (v_amount).div(25)
    v_amount = (v_amount % 25)
    v_count = (v_count + (v_amount).div(10))
    v_amount = (v_amount % 10)
    v_count = (v_count + (v_amount).div(5))
    v_amount = (v_amount % 5)
    return (v_count + v_amount)
end

raise "greedy_coin_count fixture 1: (0,) -> 0" unless greedy_coin_count(0) == 0
raise "greedy_coin_count fixture 2: (30,) -> 2" unless greedy_coin_count(30) == 2
raise "greedy_coin_count fixture 3: (41,) -> 4" unless greedy_coin_count(41) == 4
raise "greedy_coin_count fixture 4: (99,) -> 9" unless greedy_coin_count(99) == 9
puts "greedy_coin_count: 4 fixtures passed"
