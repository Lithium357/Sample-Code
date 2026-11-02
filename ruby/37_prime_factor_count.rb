# Prime factor count.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 1; counts prime factors with multiplicity.
# Run this file independently; failures exit nonzero.

def prime_factor_count(v_n)
    v_count = 0
    v_divisor = 2
    while v_divisor <= (v_n).div(v_divisor)
        while (v_n % v_divisor) == 0
            v_count = (v_count + 1)
            v_n = (v_n).div(v_divisor)
        end
        v_divisor = (v_divisor + 1)
    end
    if v_n > 1
        v_count = (v_count + 1)
    end
    return v_count
end

raise "prime_factor_count fixture 1: (1,) -> 0" unless prime_factor_count(1) == 0
raise "prime_factor_count fixture 2: (12,) -> 3" unless prime_factor_count(12) == 3
raise "prime_factor_count fixture 3: (49,) -> 2" unless prime_factor_count(49) == 2
raise "prime_factor_count fixture 4: (97,) -> 1" unless prime_factor_count(97) == 1
puts "prime_factor_count: 4 fixtures passed"
