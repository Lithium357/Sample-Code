# Next power of two.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def next_power_of_two(v_n)
    v_result = 1
    while v_result < v_n
        v_result = (v_result * 2)
    end
    return v_result
end

raise "next_power_of_two fixture 1: (0,) -> 1" unless next_power_of_two(0) == 1
raise "next_power_of_two fixture 2: (1,) -> 1" unless next_power_of_two(1) == 1
raise "next_power_of_two fixture 3: (9,) -> 16" unless next_power_of_two(9) == 16
raise "next_power_of_two fixture 4: (64,) -> 64" unless next_power_of_two(64) == 64
puts "next_power_of_two: 4 fixtures passed"
