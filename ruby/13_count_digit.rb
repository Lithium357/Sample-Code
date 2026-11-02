# Count digit.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
# Run this file independently; failures exit nonzero.

def count_digit(v_n, v_target)
    if v_n == 0
        if v_target == 0
            return 1
        end
        return 0
    end
    v_count = 0
    while v_n > 0
        if (v_n % 10) == v_target
            v_count = (v_count + 1)
        end
        v_n = (v_n).div(10)
    end
    return v_count
end

raise "count_digit fixture 1: (0, 0) -> 1" unless count_digit(0, 0) == 1
raise "count_digit fixture 2: (0, 1) -> 0" unless count_digit(0, 1) == 0
raise "count_digit fixture 3: (1001, 0) -> 2" unless count_digit(1001, 0) == 2
raise "count_digit fixture 4: (777, 7) -> 3" unless count_digit(777, 7) == 3
puts "count_digit: 4 fixtures passed"
