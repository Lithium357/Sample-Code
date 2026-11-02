# Digital root.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def digital_root(v_n)
    while v_n >= 10
        v_total = 0
        while v_n > 0
            v_total = (v_total + (v_n % 10))
            v_n = (v_n).div(10)
        end
        v_n = v_total
    end
    return v_n
end

raise "digital_root fixture 1: (0,) -> 0" unless digital_root(0) == 0
raise "digital_root fixture 2: (999,) -> 9" unless digital_root(999) == 9
raise "digital_root fixture 3: (12345,) -> 6" unless digital_root(12345) == 6
raise "digital_root fixture 4: (8,) -> 8" unless digital_root(8) == 8
puts "digital_root: 4 fixtures passed"
