# Ceil div.
# Ruby 3.x; ruby FILE.rb
# Contract: numerator >= 0; denominator > 0.
# Run this file independently; failures exit nonzero.

def ceil_div(v_numerator, v_denominator)
    v_quotient = (v_numerator).div(v_denominator)
    if (v_numerator % v_denominator) != 0
        v_quotient = (v_quotient + 1)
    end
    return v_quotient
end

raise "ceil_div fixture 1: (0, 3) -> 0" unless ceil_div(0, 3) == 0
raise "ceil_div fixture 2: (10, 3) -> 4" unless ceil_div(10, 3) == 4
raise "ceil_div fixture 3: (12, 3) -> 4" unless ceil_div(12, 3) == 4
raise "ceil_div fixture 4: (1, 9) -> 1" unless ceil_div(1, 9) == 1
puts "ceil_div: 4 fixtures passed"
