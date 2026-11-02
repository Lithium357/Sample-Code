# Lucas.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def lucas(v_n)
    v_previous = 2
    v_current = 1
    v_index = 0
    while v_index < v_n
        v_following = (v_previous + v_current)
        v_previous = v_current
        v_current = v_following
        v_index = (v_index + 1)
    end
    return v_previous
end

raise "lucas fixture 1: (0,) -> 2" unless lucas(0) == 2
raise "lucas fixture 2: (1,) -> 1" unless lucas(1) == 1
raise "lucas fixture 3: (5,) -> 11" unless lucas(5) == 11
raise "lucas fixture 4: (10,) -> 123" unless lucas(10) == 123
puts "lucas: 4 fixtures passed"
