# Population count.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def population_count(v_n)
    v_count = 0
    while v_n > 0
        v_count = (v_count + (v_n % 2))
        v_n = (v_n).div(2)
    end
    return v_count
end

raise "population_count fixture 1: (0,) -> 0" unless population_count(0) == 0
raise "population_count fixture 2: (15,) -> 4" unless population_count(15) == 4
raise "population_count fixture 3: (16,) -> 1" unless population_count(16) == 1
raise "population_count fixture 4: (255,) -> 8" unless population_count(255) == 8
puts "population_count: 4 fixtures passed"
