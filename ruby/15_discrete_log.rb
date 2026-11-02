# Discrete log.
# Ruby 3.x; ruby FILE.rb
# Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
# Run this file independently; failures exit nonzero.

def discrete_log(v_base, v_target, v_modulus)
    v_value = (1 % v_modulus)
    v_exponent = 0
    while v_exponent < v_modulus
        if v_value == v_target
            return v_exponent
        end
        v_value = ((v_value * v_base) % v_modulus)
        v_exponent = (v_exponent + 1)
    end
    return (-1)
end

raise "discrete_log fixture 1: (2, 1, 7) -> 0" unless discrete_log(2, 1, 7) == 0
raise "discrete_log fixture 2: (2, 4, 7) -> 2" unless discrete_log(2, 4, 7) == 2
raise "discrete_log fixture 3: (2, 3, 7) -> -1" unless discrete_log(2, 3, 7) == -1
raise "discrete_log fixture 4: (3, 5, 7) -> 5" unless discrete_log(3, 5, 7) == 5
puts "discrete_log: 4 fixtures passed"
