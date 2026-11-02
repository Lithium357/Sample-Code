# Is prime.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def is_prime(v_n)
    if v_n < 2
        return 0
    end
    v_divisor = 2
    while v_divisor <= (v_n).div(v_divisor)
        if (v_n % v_divisor) == 0
            return 0
        end
        v_divisor = (v_divisor + 1)
    end
    return 1
end

raise "is_prime fixture 1: (0,) -> 0" unless is_prime(0) == 0
raise "is_prime fixture 2: (1,) -> 0" unless is_prime(1) == 0
raise "is_prime fixture 3: (2,) -> 1" unless is_prime(2) == 1
raise "is_prime fixture 4: (49,) -> 0" unless is_prime(49) == 0
raise "is_prime fixture 5: (97,) -> 1" unless is_prime(97) == 1
puts "is_prime: 5 fixtures passed"
