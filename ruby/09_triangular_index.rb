# Triangular index.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def triangular_index(v_n)
    v_total = 0
    v_index = 0
    while v_total < v_n
        v_index = (v_index + 1)
        v_total = (v_total + v_index)
    end
    if v_total == v_n
        return v_index
    end
    return (-1)
end

raise "triangular_index fixture 1: (0,) -> 0" unless triangular_index(0) == 0
raise "triangular_index fixture 2: (1,) -> 1" unless triangular_index(1) == 1
raise "triangular_index fixture 3: (15,) -> 5" unless triangular_index(15) == 5
raise "triangular_index fixture 4: (14,) -> -1" unless triangular_index(14) == -1
puts "triangular_index: 4 fixtures passed"
