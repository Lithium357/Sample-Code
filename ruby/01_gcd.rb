# Gcd.
# Ruby 3.x; ruby FILE.rb
# Contract: a,b >= 0; gcd(0,0) is defined as 0.
# Run this file independently; failures exit nonzero.

def gcd(v_a, v_b)
    while v_b != 0
        v_remainder = (v_a % v_b)
        v_a = v_b
        v_b = v_remainder
    end
    return v_a
end

raise "gcd fixture 1: (48, 18) -> 6" unless gcd(48, 18) == 6
raise "gcd fixture 2: (0, 7) -> 7" unless gcd(0, 7) == 7
raise "gcd fixture 3: (7, 0) -> 7" unless gcd(7, 0) == 7
raise "gcd fixture 4: (0, 0) -> 0" unless gcd(0, 0) == 0
raise "gcd fixture 5: (35, 64) -> 1" unless gcd(35, 64) == 1
puts "gcd: 5 fixtures passed"
