# Largest prime factor.
# Ruby 3.x; ruby FILE.rb
# Contract: Integer n >= 1; returns 1 for the empty factorization of 1.
# Values outside this precondition have no promised rejection behavior.
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
# Independent bounded oracle: sieve primes once, then enumerate prime divisors
# of the ORIGINAL n. It never divides a shrinking n like the implementation.
limit = 4096
composite = Array.new(limit + 1, false)
base = 2
while base * base <= limit
    unless composite[base]
        (base * base).step(limit, base) { |multiple| composite[multiple] = true }
    end
    base += 1
end
primes = (2..limit).reject { |value| composite[value] }
(1..limit).each do |value|
    expected = primes.reverse_each.find { |prime| (value % prime).zero? } || 1
    raise "largest_prime_factor oracle mismatch for #{value}" unless largest_prime_factor(value) == expected
end
puts "largest_prime_factor: 4 fixed fixtures and 4096 bounded prime-divisor oracle cases passed"
