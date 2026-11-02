# Is armstrong.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def is_armstrong(v_n)
    v_digits = 1
    v_remaining = v_n
    while v_remaining >= 10
        v_digits = (v_digits + 1)
        v_remaining = (v_remaining).div(10)
    end
    v_total = 0
    v_remaining = v_n
    while v_remaining > 0
        v_digit = (v_remaining % 10)
        v_product = 1
        v_exponent = 0
        while v_exponent < v_digits
            v_product = (v_product * v_digit)
            v_exponent = (v_exponent + 1)
        end
        v_total = (v_total + v_product)
        v_remaining = (v_remaining).div(10)
    end
    if v_total == v_n
        return 1
    end
    return 0
end

raise "is_armstrong fixture 1: (0,) -> 1" unless is_armstrong(0) == 1
raise "is_armstrong fixture 2: (153,) -> 1" unless is_armstrong(153) == 1
raise "is_armstrong fixture 3: (9474,) -> 1" unless is_armstrong(9474) == 1
raise "is_armstrong fixture 4: (154,) -> 0" unless is_armstrong(154) == 0
puts "is_armstrong: 4 fixtures passed"
