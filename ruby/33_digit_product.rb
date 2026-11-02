# Digit product.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def digit_product(v_n)
    if v_n == 0
        return 0
    end
    v_product = 1
    while v_n > 0
        v_product = (v_product * (v_n % 10))
        v_n = (v_n).div(10)
    end
    return v_product
end

raise "digit_product fixture 1: (0,) -> 0" unless digit_product(0) == 0
raise "digit_product fixture 2: (1234,) -> 24" unless digit_product(1234) == 24
raise "digit_product fixture 3: (102,) -> 0" unless digit_product(102) == 0
raise "digit_product fixture 4: (99,) -> 81" unless digit_product(99) == 81
puts "digit_product: 4 fixtures passed"
