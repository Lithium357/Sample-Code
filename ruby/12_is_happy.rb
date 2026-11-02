# Is happy.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
# Run this file independently; failures exit nonzero.

def is_happy(v_n)
    v_steps = 0
    while v_steps < 100
        if v_n == 1
            return 1
        end
        v_total = 0
        while v_n > 0
            v_digit = (v_n % 10)
            v_total = (v_total + (v_digit * v_digit))
            v_n = (v_n).div(10)
        end
        v_n = v_total
        v_steps = (v_steps + 1)
    end
    return 0
end

raise "is_happy fixture 1: (1,) -> 1" unless is_happy(1) == 1
raise "is_happy fixture 2: (19,) -> 1" unless is_happy(19) == 1
raise "is_happy fixture 3: (2,) -> 0" unless is_happy(2) == 0
raise "is_happy fixture 4: (0,) -> 0" unless is_happy(0) == 0
puts "is_happy: 4 fixtures passed"
