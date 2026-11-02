# Is palindrome.
# Ruby 3.x; ruby FILE.rb
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

def is_palindrome(v_n)
    v_original = v_n
    v_reversed_value = 0
    while v_n > 0
        v_reversed_value = ((v_reversed_value * 10) + (v_n % 10))
        v_n = (v_n).div(10)
    end
    if v_reversed_value == v_original
        return 1
    end
    return 0
end

raise "is_palindrome fixture 1: (0,) -> 1" unless is_palindrome(0) == 1
raise "is_palindrome fixture 2: (1221,) -> 1" unless is_palindrome(1221) == 1
raise "is_palindrome fixture 3: (123,) -> 0" unless is_palindrome(123) == 0
raise "is_palindrome fixture 4: (101,) -> 1" unless is_palindrome(101) == 1
puts "is_palindrome: 4 fixtures passed"
