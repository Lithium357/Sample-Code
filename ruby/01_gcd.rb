# Gcd.
# Ruby 3.x; ruby FILE.rb
# Contract: nonnegative Integer inputs; gcd(0,0) is defined as 0.
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
maximum = (1 << 63) - 1
[[maximum,maximum,maximum], [maximum,0,maximum], [maximum,maximum-1,1],
 [3_000_000_000,2_000_000_000,1_000_000_000], [832040,514229,1],
 [3*(1<<200),5*(1<<200),1<<200]].each do |a,b,expected|
    raise 'gcd boundary fixture' unless gcd(a,b) == expected
end
# Independent reference enumerates divisors, including the (0,0) empty range.
(0..32).each do |a|
    (0..32).each do |b|
        expected = 0
        (1..[a,b].max).each { |divisor| expected=divisor if a%divisor==0 && b%divisor==0 }
        raise "gcd oracle (#{a},#{b})" unless gcd(a,b) == expected
    end
end
puts "gcd: 11 fixed fixtures and 1089 divisor-oracle pairs passed"
