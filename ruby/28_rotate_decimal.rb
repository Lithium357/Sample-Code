# Rotate decimal.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def rotate_decimal(v_n)
    if v_n < 10
        return v_n
    end
    v_scale = 1
    v_remaining = v_n
    while v_remaining >= 10
        v_scale = (v_scale * 10)
        v_remaining = (v_remaining).div(10)
    end
    return (((v_n % 10) * v_scale) + (v_n).div(10))
end

raise "rotate_decimal fixture 1: (0,) -> 0" unless rotate_decimal(0) == 0
raise "rotate_decimal fixture 2: (7,) -> 7" unless rotate_decimal(7) == 7
raise "rotate_decimal fixture 3: (1234,) -> 4123" unless rotate_decimal(1234) == 4123
raise "rotate_decimal fixture 4: (120,) -> 12" unless rotate_decimal(120) == 12
puts "rotate_decimal: 4 fixtures passed"
