# Lattice paths.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def lattice_paths(v_width, v_height)
    v_steps = (v_width + v_height)
    v_result = 1
    v_index = 1
    while v_index <= v_width
        v_result = ((v_result * ((v_steps - v_width) + v_index))).div(v_index)
        v_index = (v_index + 1)
    end
    return v_result
end

raise "lattice_paths fixture 1: (0, 0) -> 1" unless lattice_paths(0, 0) == 1
raise "lattice_paths fixture 2: (2, 2) -> 6" unless lattice_paths(2, 2) == 6
raise "lattice_paths fixture 3: (3, 2) -> 10" unless lattice_paths(3, 2) == 10
raise "lattice_paths fixture 4: (4, 4) -> 70" unless lattice_paths(4, 4) == 70
puts "lattice_paths: 4 fixtures passed"
