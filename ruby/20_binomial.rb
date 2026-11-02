# Binomial.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def binomial(v_n, v_k)
    if v_k > v_n
        return 0
    end
    if v_k > (v_n - v_k)
        v_k = (v_n - v_k)
    end
    v_result = 1
    v_index = 1
    while v_index <= v_k
        v_result = ((v_result * ((v_n - v_k) + v_index))).div(v_index)
        v_index = (v_index + 1)
    end
    return v_result
end

raise "binomial fixture 1: (5, 2) -> 10" unless binomial(5, 2) == 10
raise "binomial fixture 2: (0, 0) -> 1" unless binomial(0, 0) == 1
raise "binomial fixture 3: (6, 7) -> 0" unless binomial(6, 7) == 0
raise "binomial fixture 4: (10, 5) -> 252" unless binomial(10, 5) == 252
puts "binomial: 4 fixtures passed"
