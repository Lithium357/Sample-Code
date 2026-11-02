# Totient.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 1.
# Run this file independently; failures exit nonzero.

def totient(v_n)
    v_result = v_n
    v_prime = 2
    v_remaining = v_n
    while v_prime <= (v_remaining).div(v_prime)
        if (v_remaining % v_prime) == 0
            while (v_remaining % v_prime) == 0
                v_remaining = (v_remaining).div(v_prime)
            end
            v_result = (v_result - (v_result).div(v_prime))
        end
        v_prime = (v_prime + 1)
    end
    if v_remaining > 1
        v_result = (v_result - (v_result).div(v_remaining))
    end
    return v_result
end

raise "totient fixture 1: (1,) -> 1" unless totient(1) == 1
raise "totient fixture 2: (9,) -> 6" unless totient(9) == 6
raise "totient fixture 3: (12,) -> 4" unless totient(12) == 4
raise "totient fixture 4: (97,) -> 96" unless totient(97) == 96
puts "totient: 4 fixtures passed"
