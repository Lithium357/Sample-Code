# Trailing zero bits.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
# Run this file independently; failures exit nonzero.

def trailing_zero_bits(v_n)
    if v_n == 0
        return (-1)
    end
    v_count = 0
    while (v_n % 2) == 0
        v_count = (v_count + 1)
        v_n = (v_n).div(2)
    end
    return v_count
end

raise "trailing_zero_bits fixture 1: (0,) -> -1" unless trailing_zero_bits(0) == -1
raise "trailing_zero_bits fixture 2: (1,) -> 0" unless trailing_zero_bits(1) == 0
raise "trailing_zero_bits fixture 3: (40,) -> 3" unless trailing_zero_bits(40) == 3
raise "trailing_zero_bits fixture 4: (64,) -> 6" unless trailing_zero_bits(64) == 6
puts "trailing_zero_bits: 4 fixtures passed"
