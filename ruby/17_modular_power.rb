# Modular power.
# Ruby 3.x; ruby FILE.rb
# Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
# Run this file independently; failures exit nonzero.

def modular_power(v_base, v_exponent, v_modulus)
    v_result = (1 % v_modulus)
    v_base = (v_base % v_modulus)
    while v_exponent > 0
        if (v_exponent % 2) == 1
            v_result = ((v_result * v_base) % v_modulus)
        end
        v_exponent = (v_exponent).div(2)
        v_base = ((v_base * v_base) % v_modulus)
    end
    return v_result
end

raise "modular_power fixture 1: (2, 10, 1000) -> 24" unless modular_power(2, 10, 1000) == 24
raise "modular_power fixture 2: (7, 0, 1) -> 0" unless modular_power(7, 0, 1) == 0
raise "modular_power fixture 3: (3, 4, 7) -> 4" unless modular_power(3, 4, 7) == 4
raise "modular_power fixture 4: (5, 3, 13) -> 8" unless modular_power(5, 3, 13) == 8
puts "modular_power: 4 fixtures passed"
