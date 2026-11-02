# Is power of two.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def is_power_of_two(v_n)
    if v_n == 0
        return 0
    end
    while (v_n % 2) == 0
        v_n = (v_n).div(2)
    end
    if v_n == 1
        return 1
    end
    return 0
end

raise "is_power_of_two fixture 1: (0,) -> 0" unless is_power_of_two(0) == 0
raise "is_power_of_two fixture 2: (1,) -> 1" unless is_power_of_two(1) == 1
raise "is_power_of_two fixture 3: (12,) -> 0" unless is_power_of_two(12) == 0
raise "is_power_of_two fixture 4: (64,) -> 1" unless is_power_of_two(64) == 1
puts "is_power_of_two: 4 fixtures passed"
