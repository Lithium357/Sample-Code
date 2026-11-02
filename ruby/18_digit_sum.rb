# Digit sum.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def digit_sum(v_n)
    v_total = 0
    while v_n > 0
        v_total = (v_total + (v_n % 10))
        v_n = (v_n).div(10)
    end
    return v_total
end

raise "digit_sum fixture 1: (0,) -> 0" unless digit_sum(0) == 0
raise "digit_sum fixture 2: (12345,) -> 15" unless digit_sum(12345) == 15
raise "digit_sum fixture 3: (909,) -> 18" unless digit_sum(909) == 18
raise "digit_sum fixture 4: (1000,) -> 1" unless digit_sum(1000) == 1
puts "digit_sum: 4 fixtures passed"
