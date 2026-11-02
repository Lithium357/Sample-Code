# Integer log.
# Ruby 3.x; ruby FILE.rb
# Contract: n >= 1; base >= 2; returns floor(log_base(n)).
# Run this file independently; failures exit nonzero.

def integer_log(v_n, v_base)
    v_exponent = 0
    while v_n >= v_base
        v_n = (v_n).div(v_base)
        v_exponent = (v_exponent + 1)
    end
    return v_exponent
end

raise "integer_log fixture 1: (1, 2) -> 0" unless integer_log(1, 2) == 0
raise "integer_log fixture 2: (8, 2) -> 3" unless integer_log(8, 2) == 3
raise "integer_log fixture 3: (99, 10) -> 1" unless integer_log(99, 10) == 1
raise "integer_log fixture 4: (100, 10) -> 2" unless integer_log(100, 10) == 2
puts "integer_log: 4 fixtures passed"
