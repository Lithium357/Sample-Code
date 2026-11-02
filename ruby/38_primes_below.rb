# Primes below.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def primes_below(v_limit)
    v_total = 0
    v_candidate = 2
    while v_candidate < v_limit
        v_prime = 1
        v_divisor = 2
        while v_divisor <= (v_candidate).div(v_divisor)
            if (v_candidate % v_divisor) == 0
                v_prime = 0
            end
            v_divisor = (v_divisor + 1)
        end
        v_total = (v_total + v_prime)
        v_candidate = (v_candidate + 1)
    end
    return v_total
end

raise "primes_below fixture 1: (2,) -> 0" unless primes_below(2) == 0
raise "primes_below fixture 2: (3,) -> 1" unless primes_below(3) == 1
raise "primes_below fixture 3: (10,) -> 4" unless primes_below(10) == 4
raise "primes_below fixture 4: (100,) -> 25" unless primes_below(100) == 25
puts "primes_below: 4 fixtures passed"
