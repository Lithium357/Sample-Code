# Power.
# Ruby 3.x; ruby FILE.rb
# Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
# Run this file independently; failures exit nonzero.

def power(v_base, v_exponent)
    v_result = 1
    while v_exponent > 0
        if (v_exponent % 2) == 1
            v_result = (v_result * v_base)
        end
        v_exponent = (v_exponent).div(2)
        if v_exponent > 0
            v_base = (v_base * v_base)
        end
    end
    return v_result
end

raise "power fixture 1: (0, 0) -> 1" unless power(0, 0) == 1
raise "power fixture 2: (2, 10) -> 1024" unless power(2, 10) == 1024
raise "power fixture 3: (3, 5) -> 243" unless power(3, 5) == 243
raise "power fixture 4: (7, 1) -> 7" unless power(7, 1) == 7
puts "power: 4 fixtures passed"
