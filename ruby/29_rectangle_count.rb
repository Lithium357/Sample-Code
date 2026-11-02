# Rectangle count.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def rectangle_count(v_width, v_height)
    v_horizontal = ((v_width * (v_width + 1))).div(2)
    v_vertical = ((v_height * (v_height + 1))).div(2)
    return (v_horizontal * v_vertical)
end

raise "rectangle_count fixture 1: (0, 4) -> 0" unless rectangle_count(0, 4) == 0
raise "rectangle_count fixture 2: (1, 1) -> 1" unless rectangle_count(1, 1) == 1
raise "rectangle_count fixture 3: (2, 3) -> 18" unless rectangle_count(2, 3) == 18
raise "rectangle_count fixture 4: (4, 4) -> 100" unless rectangle_count(4, 4) == 100
puts "rectangle_count: 4 fixtures passed"
