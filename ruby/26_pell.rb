# Pell.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def pell(v_n)
    v_previous = 0
    v_current = 1
    v_index = 0
    while v_index < v_n
        v_following = ((2 * v_current) + v_previous)
        v_previous = v_current
        v_current = v_following
        v_index = (v_index + 1)
    end
    return v_previous
end

raise "pell fixture 1: (0,) -> 0" unless pell(0) == 0
raise "pell fixture 2: (1,) -> 1" unless pell(1) == 1
raise "pell fixture 3: (5,) -> 29" unless pell(5) == 29
raise "pell fixture 4: (10,) -> 2378" unless pell(10) == 2378
puts "pell: 4 fixtures passed"
