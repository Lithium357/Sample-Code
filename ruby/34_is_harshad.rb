# Is harshad.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def is_harshad(v_n)
    if v_n == 0
        return 0
    end
    v_remaining = v_n
    v_total = 0
    while v_remaining > 0
        v_total = (v_total + (v_remaining % 10))
        v_remaining = (v_remaining).div(10)
    end
    if (v_n % v_total) == 0
        return 1
    end
    return 0
end

raise "is_harshad fixture 1: (0,) -> 0" unless is_harshad(0) == 0
raise "is_harshad fixture 2: (18,) -> 1" unless is_harshad(18) == 1
raise "is_harshad fixture 3: (19,) -> 0" unless is_harshad(19) == 0
raise "is_harshad fixture 4: (100,) -> 1" unless is_harshad(100) == 1
puts "is_harshad: 4 fixtures passed"
