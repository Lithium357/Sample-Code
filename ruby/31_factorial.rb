# Factorial.
# Ruby 3.x; ruby FILE.rb
# Contract: 0 <= n <= 12; larger values exceed CMD signed 32-bit arithmetic.
# Run this file independently; failures exit nonzero.

def factorial(v_n)
    v_result = 1
    v_factor = 2
    while v_factor <= v_n
        v_result = (v_result * v_factor)
        v_factor = (v_factor + 1)
    end
    return v_result
end

raise "factorial fixture 1: (0,) -> 1" unless factorial(0) == 1
raise "factorial fixture 2: (1,) -> 1" unless factorial(1) == 1
raise "factorial fixture 3: (5,) -> 120" unless factorial(5) == 120
raise "factorial fixture 4: (10,) -> 3628800" unless factorial(10) == 3628800
puts "factorial: 4 fixtures passed"
