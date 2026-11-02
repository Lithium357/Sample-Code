# Multiply mod.
# Ruby 3.x; ruby FILE.rb
# Contract: a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.
# Run this file independently; failures exit nonzero.

def multiply_mod(v_a, v_b, v_modulus)
    v_result = 0
    v_a = (v_a % v_modulus)
    while v_b > 0
        if (v_b % 2) == 1
            v_result = ((v_result + v_a) % v_modulus)
        end
        v_a = ((v_a * 2) % v_modulus)
        v_b = (v_b).div(2)
    end
    return v_result
end

raise "multiply_mod fixture 1: (12, 13, 7) -> 2" unless multiply_mod(12, 13, 7) == 2
raise "multiply_mod fixture 2: (0, 9, 3) -> 0" unless multiply_mod(0, 9, 3) == 0
raise "multiply_mod fixture 3: (123, 456, 97) -> 22" unless multiply_mod(123, 456, 97) == 22
raise "multiply_mod fixture 4: (5, 9, 1) -> 0" unless multiply_mod(5, 9, 1) == 0
puts "multiply_mod: 4 fixtures passed"
