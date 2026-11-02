# Largest prime factor.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 1; returns 1 for the empty factorization of 1.
# Run this file independently; failures exit nonzero.

def largest_prime_factor(v_n)
    v_largest = 1
    v_divisor = 2
    while v_divisor <= (v_n).div(v_divisor)
        while (v_n % v_divisor) == 0
            v_largest = v_divisor
            v_n = (v_n).div(v_divisor)
        end
        v_divisor = (v_divisor + 1)
    end
    if v_n > 1
        v_largest = v_n
    end
    return v_largest
end

raise "largest_prime_factor fixture 1: (1,) -> 1" unless largest_prime_factor(1) == 1
raise "largest_prime_factor fixture 2: (12,) -> 3" unless largest_prime_factor(12) == 3
raise "largest_prime_factor fixture 3: (49,) -> 7" unless largest_prime_factor(49) == 7
raise "largest_prime_factor fixture 4: (97,) -> 97" unless largest_prime_factor(97) == 97
puts "largest_prime_factor: 4 fixtures passed"
