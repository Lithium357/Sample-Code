# Lcm.
# Ruby 3.x; ruby FILE.rb
# Contract: a,b >= 0; zero arguments produce 0.
# Run this file independently; failures exit nonzero.

def lcm(v_a, v_b)
    if v_a == 0
        return 0
    end
    if v_b == 0
        return 0
    end
    v_x = v_a
    v_y = v_b
    while v_y != 0
        v_remainder = (v_x % v_y)
        v_x = v_y
        v_y = v_remainder
    end
    return ((v_a).div(v_x) * v_b)
end

raise "lcm fixture 1: (12, 18) -> 36" unless lcm(12, 18) == 36
raise "lcm fixture 2: (0, 7) -> 0" unless lcm(0, 7) == 0
raise "lcm fixture 3: (7, 0) -> 0" unless lcm(7, 0) == 0
raise "lcm fixture 4: (5, 7) -> 35" unless lcm(5, 7) == 35
raise "lcm fixture 5: (9, 9) -> 9" unless lcm(9, 9) == 9
puts "lcm: 5 fixtures passed"
