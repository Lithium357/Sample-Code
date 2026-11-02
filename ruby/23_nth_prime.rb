# Nth prime.
# Ruby 3.x; ruby FILE.rb
# Contract: 1 <= index <= 100; trial division is intended for small inputs.
# Run this file independently; failures exit nonzero.

def nth_prime(v_index)
    v_count = 0
    v_candidate = 1
    while v_count < v_index
        v_candidate = (v_candidate + 1)
        v_prime = 1
        v_divisor = 2
        while v_divisor <= (v_candidate).div(v_divisor)
            if (v_candidate % v_divisor) == 0
                v_prime = 0
            end
            v_divisor = (v_divisor + 1)
        end
        v_count = (v_count + v_prime)
    end
    return v_candidate
end

raise "nth_prime fixture 1: (1,) -> 2" unless nth_prime(1) == 2
raise "nth_prime fixture 2: (2,) -> 3" unless nth_prime(2) == 3
raise "nth_prime fixture 3: (10,) -> 29" unless nth_prime(10) == 29
raise "nth_prime fixture 4: (25,) -> 97" unless nth_prime(25) == 97
puts "nth_prime: 4 fixtures passed"
