# Modular inverse.
# Ruby 3.x; ruby FILE.rb
# Contract: a >= 0; modulus > 1; returns -1 when no inverse exists.
# Run this file independently; failures exit nonzero.

def modular_inverse(v_a, v_modulus)
    v_candidate = 1
    while v_candidate < v_modulus
        if ((v_a * v_candidate) % v_modulus) == 1
            return v_candidate
        end
        v_candidate = (v_candidate + 1)
    end
    return (-1)
end

raise "modular_inverse fixture 1: (3, 7) -> 5" unless modular_inverse(3, 7) == 5
raise "modular_inverse fixture 2: (2, 4) -> -1" unless modular_inverse(2, 4) == -1
raise "modular_inverse fixture 3: (1, 5) -> 1" unless modular_inverse(1, 5) == 1
raise "modular_inverse fixture 4: (7, 11) -> 8" unless modular_inverse(7, 11) == 8
puts "modular_inverse: 4 fixtures passed"
