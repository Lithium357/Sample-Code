# Is perfect.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def is_perfect(v_n)
    v_total = 0
    v_divisor = 1
    while v_divisor < v_n
        if (v_n % v_divisor) == 0
            v_total = (v_total + v_divisor)
        end
        v_divisor = (v_divisor + 1)
    end
    if v_total == v_n
        if v_n > 0
            return 1
        end
    end
    return 0
end

raise "is_perfect fixture 1: (0,) -> 0" unless is_perfect(0) == 0
raise "is_perfect fixture 2: (1,) -> 0" unless is_perfect(1) == 0
raise "is_perfect fixture 3: (6,) -> 1" unless is_perfect(6) == 1
raise "is_perfect fixture 4: (28,) -> 1" unless is_perfect(28) == 1
raise "is_perfect fixture 5: (12,) -> 0" unless is_perfect(12) == 0
puts "is_perfect: 5 fixtures passed"
