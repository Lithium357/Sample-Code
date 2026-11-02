# Is leap year.
# Ruby 3.x; ruby FILE.rb
# Contract: year >= 1; proleptic Gregorian calendar.
# Run this file independently; failures exit nonzero.

def is_leap_year(v_year)
    if (v_year % 400) == 0
        return 1
    end
    if (v_year % 100) == 0
        return 0
    end
    if (v_year % 4) == 0
        return 1
    end
    return 0
end

raise "is_leap_year fixture 1: (1900,) -> 0" unless is_leap_year(1900) == 0
raise "is_leap_year fixture 2: (2000,) -> 1" unless is_leap_year(2000) == 1
raise "is_leap_year fixture 3: (2024,) -> 1" unless is_leap_year(2024) == 1
raise "is_leap_year fixture 4: (2023,) -> 0" unless is_leap_year(2023) == 0
puts "is_leap_year: 4 fixtures passed"
