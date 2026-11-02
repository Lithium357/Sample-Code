"""Executable specifications for the parallel integer-algorithm examples.

Only bounded integer arithmetic is used. Explicit fixtures are independent of
the generated language implementations. Each function is emitted separately.
"""

def gcd(a, b):
    while b != 0:
        remainder = a % b
        a = b
        b = remainder
    return a

def lcm(a, b):
    if a == 0:
        return 0
    if b == 0:
        return 0
    x = a
    y = b
    while y != 0:
        remainder = x % y
        x = y
        y = remainder
    return (a // x) * b

def factorial(n):
    result = 1
    factor = 2
    while factor <= n:
        result = result * factor
        factor = factor + 1
    return result

def fibonacci(n):
    previous = 0
    current = 1
    index = 0
    while index < n:
        following = previous + current
        previous = current
        current = following
        index = index + 1
    return previous

def tribonacci(n):
    first = 0
    second = 0
    third = 1
    index = 0
    while index < n:
        following = first + second + third
        first = second
        second = third
        third = following
        index = index + 1
    return first

def power(base, exponent):
    result = 1
    while exponent > 0:
        if exponent % 2 == 1:
            result = result * base
        exponent = exponent // 2
        if exponent > 0:
            base = base * base
    return result

def modular_power(base, exponent, modulus):
    result = 1 % modulus
    base = base % modulus
    while exponent > 0:
        if exponent % 2 == 1:
            result = (result * base) % modulus
        exponent = exponent // 2
        base = (base * base) % modulus
    return result

def is_prime(n):
    if n < 2:
        return 0
    divisor = 2
    while divisor <= n // divisor:
        if n % divisor == 0:
            return 0
        divisor = divisor + 1
    return 1

def divisor_count(n):
    count = 0
    divisor = 1
    while divisor <= n // divisor:
        if n % divisor == 0:
            count = count + 1
            if divisor != n // divisor:
                count = count + 1
        divisor = divisor + 1
    return count

def divisor_sum(n):
    total = 0
    divisor = 1
    while divisor <= n // divisor:
        if n % divisor == 0:
            total = total + divisor
            if divisor != n // divisor:
                total = total + n // divisor
        divisor = divisor + 1
    return total

def is_perfect(n):
    total = 0
    divisor = 1
    while divisor < n:
        if n % divisor == 0:
            total = total + divisor
        divisor = divisor + 1
    if total == n:
        if n > 0:
            return 1
    return 0

def digit_sum(n):
    total = 0
    while n > 0:
        total = total + n % 10
        n = n // 10
    return total

def digit_product(n):
    if n == 0:
        return 0
    product = 1
    while n > 0:
        product = product * (n % 10)
        n = n // 10
    return product

def digit_count(n):
    count = 1
    while n >= 10:
        count = count + 1
        n = n // 10
    return count

def reverse_digits(n):
    result = 0
    while n > 0:
        result = result * 10 + n % 10
        n = n // 10
    return result

def is_palindrome(n):
    original = n
    reversed_value = 0
    while n > 0:
        reversed_value = reversed_value * 10 + n % 10
        n = n // 10
    if reversed_value == original:
        return 1
    return 0

def digital_root(n):
    while n >= 10:
        total = 0
        while n > 0:
            total = total + n % 10
            n = n // 10
        n = total
    return n

def is_harshad(n):
    if n == 0:
        return 0
    remaining = n
    total = 0
    while remaining > 0:
        total = total + remaining % 10
        remaining = remaining // 10
    if n % total == 0:
        return 1
    return 0

def collatz_steps(n):
    steps = 0
    while n > 1:
        if n % 2 == 0:
            n = n // 2
        else:
            n = 3 * n + 1
        steps = steps + 1
    return steps

def integer_sqrt(n):
    low = 0
    high = n
    answer = 0
    while low <= high:
        middle = low + (high - low) // 2
        if middle == 0:
            answer = 0
            low = 1
        else:
            if middle <= n // middle:
                answer = middle
                low = middle + 1
            else:
                high = middle - 1
    return answer

def ceil_div(numerator, denominator):
    quotient = numerator // denominator
    if numerator % denominator != 0:
        quotient = quotient + 1
    return quotient

def binomial(n, k):
    if k > n:
        return 0
    if k > n - k:
        k = n - k
    result = 1
    index = 1
    while index <= k:
        result = result * (n - k + index) // index
        index = index + 1
    return result

def population_count(n):
    count = 0
    while n > 0:
        count = count + n % 2
        n = n // 2
    return count

def binary_length(n):
    length = 0
    while n > 0:
        length = length + 1
        n = n // 2
    return length

def reverse_bits(n, width):
    result = 0
    index = 0
    while index < width:
        result = result * 2 + n % 2
        n = n // 2
        index = index + 1
    return result

def trailing_zero_bits(n):
    if n == 0:
        return -1
    count = 0
    while n % 2 == 0:
        count = count + 1
        n = n // 2
    return count

def next_power_of_two(n):
    result = 1
    while result < n:
        result = result * 2
    return result

def is_power_of_two(n):
    if n == 0:
        return 0
    while n % 2 == 0:
        n = n // 2
    if n == 1:
        return 1
    return 0

def gray_encode(n):
    lower = n // 2
    result = 0
    place = 1
    while n > 0:
        if n % 2 != lower % 2:
            result = result + place
        n = n // 2
        lower = lower // 2
        place = place * 2
    return result

def gray_decode(gray):
    result = 0
    parity = 0
    place = 1
    remaining = gray
    while remaining > 0:
        place = place * 2
        remaining = remaining // 2
    place = place // 2
    while place > 0:
        bit = gray // place % 2
        parity = (parity + bit) % 2
        result = result * 2 + parity
        place = place // 2
    return result

def totient(n):
    result = n
    prime = 2
    remaining = n
    while prime <= remaining // prime:
        if remaining % prime == 0:
            while remaining % prime == 0:
                remaining = remaining // prime
            result = result - result // prime
        prime = prime + 1
    if remaining > 1:
        result = result - result // remaining
    return result

def largest_prime_factor(n):
    largest = 1
    divisor = 2
    while divisor <= n // divisor:
        while n % divisor == 0:
            largest = divisor
            n = n // divisor
        divisor = divisor + 1
    if n > 1:
        largest = n
    return largest

def prime_factor_count(n):
    count = 0
    divisor = 2
    while divisor <= n // divisor:
        while n % divisor == 0:
            count = count + 1
            n = n // divisor
        divisor = divisor + 1
    if n > 1:
        count = count + 1
    return count

def josephus(n, step):
    survivor = 0
    size = 2
    while size <= n:
        survivor = (survivor + step) % size
        size = size + 1
    return survivor

def bounded_coin_count(amount):
    count = 0
    quarters = 0
    while quarters * 25 <= amount:
        dimes = 0
        while quarters * 25 + dimes * 10 <= amount:
            remainder = amount - quarters * 25 - dimes * 10
            count = count + remainder // 5 + 1
            dimes = dimes + 1
        quarters = quarters + 1
    return count

def greedy_coin_count(amount):
    count = amount // 25
    amount = amount % 25
    count = count + amount // 10
    amount = amount % 10
    count = count + amount // 5
    amount = amount % 5
    return count + amount

def nth_prime(index):
    count = 0
    candidate = 1
    while count < index:
        candidate = candidate + 1
        prime = 1
        divisor = 2
        while divisor <= candidate // divisor:
            if candidate % divisor == 0:
                prime = 0
            divisor = divisor + 1
        count = count + prime
    return candidate

def primes_below(limit):
    total = 0
    candidate = 2
    while candidate < limit:
        prime = 1
        divisor = 2
        while divisor <= candidate // divisor:
            if candidate % divisor == 0:
                prime = 0
            divisor = divisor + 1
        total = total + prime
        candidate = candidate + 1
    return total

def sum_of_squares(n):
    total = 0
    index = 1
    while index <= n:
        total = total + index * index
        index = index + 1
    return total

def sum_of_cubes(n):
    total = 0
    index = 1
    while index <= n:
        total = total + index * index * index
        index = index + 1
    return total

def triangular_index(n):
    total = 0
    index = 0
    while total < n:
        index = index + 1
        total = total + index
    if total == n:
        return index
    return -1

def is_leap_year(year):
    if year % 400 == 0:
        return 1
    if year % 100 == 0:
        return 0
    if year % 4 == 0:
        return 1
    return 0

def days_in_month(year, month):
    if month == 2:
        if year % 400 == 0:
            return 29
        if year % 100 == 0:
            return 28
        if year % 4 == 0:
            return 29
        return 28
    if month == 4:
        return 30
    if month == 6:
        return 30
    if month == 9:
        return 30
    if month == 11:
        return 30
    return 31

def clamp(value, low, high):
    if value < low:
        return low
    if value > high:
        return high
    return value

def median_three(a, b, c):
    if a > b:
        swap = a
        a = b
        b = swap
    if b > c:
        swap = b
        b = c
        c = swap
    if a > b:
        b = a
    return b

def integer_log(n, base):
    exponent = 0
    while n >= base:
        n = n // base
        exponent = exponent + 1
    return exponent

def multiply_mod(a, b, modulus):
    result = 0
    a = a % modulus
    while b > 0:
        if b % 2 == 1:
            result = (result + a) % modulus
        a = (a * 2) % modulus
        b = b // 2
    return result

def fibonacci_mod(n, modulus):
    previous = 0
    current = 1 % modulus
    index = 0
    while index < n:
        following = (previous + current) % modulus
        previous = current
        current = following
        index = index + 1
    return previous

def catalan(n):
    value = 1
    index = 0
    while index < n:
        value = value * 2 * (2 * index + 1) // (index + 2)
        index = index + 1
    return value

def derangements(n):
    if n == 0:
        return 1
    previous = 1
    current = 0
    index = 2
    while index <= n:
        following = (index - 1) * (current + previous)
        previous = current
        current = following
        index = index + 1
    return current

def lucas(n):
    previous = 2
    current = 1
    index = 0
    while index < n:
        following = previous + current
        previous = current
        current = following
        index = index + 1
    return previous

def pell(n):
    previous = 0
    current = 1
    index = 0
    while index < n:
        following = 2 * current + previous
        previous = current
        current = following
        index = index + 1
    return previous

def mobius(n):
    parity = 0
    divisor = 2
    while divisor <= n // divisor:
        if n % divisor == 0:
            n = n // divisor
            parity = parity + 1
            if n % divisor == 0:
                return 0
        divisor = divisor + 1
    if n > 1:
        parity = parity + 1
    if parity % 2 == 0:
        return 1
    return -1

def is_square_free(n):
    divisor = 2
    while divisor <= n // divisor:
        square = divisor * divisor
        if n % square == 0:
            return 0
        divisor = divisor + 1
    return 1

def is_smooth(n, bound):
    divisor = 2
    while divisor <= bound:
        while n % divisor == 0:
            n = n // divisor
        divisor = divisor + 1
    if n == 1:
        return 1
    return 0

def is_happy(n):
    steps = 0
    while steps < 100:
        if n == 1:
            return 1
        total = 0
        while n > 0:
            digit = n % 10
            total = total + digit * digit
            n = n // 10
        n = total
        steps = steps + 1
    return 0

def is_armstrong(n):
    digits = 1
    remaining = n
    while remaining >= 10:
        digits = digits + 1
        remaining = remaining // 10
    total = 0
    remaining = n
    while remaining > 0:
        digit = remaining % 10
        product = 1
        exponent = 0
        while exponent < digits:
            product = product * digit
            exponent = exponent + 1
        total = total + product
        remaining = remaining // 10
    if total == n:
        return 1
    return 0

def is_automorphic(n):
    scale = 10
    remaining = n
    while remaining >= 10:
        scale = scale * 10
        remaining = remaining // 10
    if n * n % scale == n:
        return 1
    return 0

def multiplicative_persistence(n):
    steps = 0
    while n >= 10:
        product = 1
        while n > 0:
            product = product * (n % 10)
            n = n // 10
        n = product
        steps = steps + 1
    return steps

def additive_persistence(n):
    steps = 0
    while n >= 10:
        total = 0
        while n > 0:
            total = total + n % 10
            n = n // 10
        n = total
        steps = steps + 1
    return steps

def count_digit(n, target):
    if n == 0:
        if target == 0:
            return 1
        return 0
    count = 0
    while n > 0:
        if n % 10 == target:
            count = count + 1
        n = n // 10
    return count

def rotate_decimal(n):
    if n < 10:
        return n
    scale = 1
    remaining = n
    while remaining >= 10:
        scale = scale * 10
        remaining = remaining // 10
    return (n % 10) * scale + n // 10

def base_digit_sum(n, base):
    total = 0
    while n > 0:
        total = total + n % base
        n = n // base
    return total

def factorial_zeros(n):
    zeros = 0
    while n > 0:
        n = n // 5
        zeros = zeros + n
    return zeros

def pascal_row_sum(n):
    total = 1
    coefficient = 1
    index = 1
    while index <= n:
        coefficient = coefficient * (n - index + 1) // index
        total = total + coefficient
        index = index + 1
    return total

def lattice_paths(width, height):
    steps = width + height
    result = 1
    index = 1
    while index <= width:
        result = result * (steps - width + index) // index
        index = index + 1
    return result

def rectangle_count(width, height):
    horizontal = width * (width + 1) // 2
    vertical = height * (height + 1) // 2
    return horizontal * vertical

def square_count(n):
    total = 0
    side = 1
    while side <= n:
        positions = n - side + 1
        total = total + positions * positions
        side = side + 1
    return total

def digit_factorial_sum(n):
    if n == 0:
        return 1
    total = 0
    while n > 0:
        digit = n % 10
        factorial = 1
        factor = 2
        while factor <= digit:
            factorial = factorial * factor
            factor = factor + 1
        total = total + factorial
        n = n // 10
    return total

def happy_steps(n):
    steps = 0
    while steps < 100:
        if n == 1:
            return steps
        total = 0
        while n > 0:
            digit = n % 10
            total = total + digit * digit
            n = n // 10
        n = total
        steps = steps + 1
    return -1

def discrete_log(base, target, modulus):
    value = 1 % modulus
    exponent = 0
    while exponent < modulus:
        if value == target:
            return exponent
        value = value * base % modulus
        exponent = exponent + 1
    return -1

def modular_inverse(a, modulus):
    candidate = 1
    while candidate < modulus:
        if a * candidate % modulus == 1:
            return candidate
        candidate = candidate + 1
    return -1

def is_abundant(n):
    total = 0
    divisor = 1
    while divisor < n:
        if n % divisor == 0:
            total = total + divisor
        divisor = divisor + 1
    if total > n:
        return 1
    return 0

def aliquot_sum(n):
    total = 0
    divisor = 1
    while divisor < n:
        if n % divisor == 0:
            total = total + divisor
        divisor = divisor + 1
    return total

# Each case is (positional arguments, expected integer). Domains are intentionally
# small enough for signed 32-bit CMD arithmetic and for transparent hand checks.
CASES = {
 'gcd': [((48,18),6), ((0,7),7), ((7,0),7), ((0,0),0), ((35,64),1)],
 'lcm': [((12,18),36), ((0,7),0), ((7,0),0), ((5,7),35), ((9,9),9)],
 'factorial': [((0,),1), ((1,),1), ((5,),120), ((10,),3628800)],
 'fibonacci': [((0,),0), ((1,),1), ((2,),1), ((10,),55), ((20,),6765)],
 'tribonacci': [((0,),0), ((1,),0), ((2,),1), ((5,),4), ((10,),81)],
 'power': [((0,0),1), ((2,10),1024), ((3,5),243), ((7,1),7)],
 'modular_power': [((2,10,1000),24), ((7,0,1),0), ((3,4,7),4), ((5,3,13),8)],
 'is_prime': [((0,),0), ((1,),0), ((2,),1), ((49,),0), ((97,),1)],
 'divisor_count': [((1,),1), ((12,),6), ((36,),9), ((97,),2)],
 'divisor_sum': [((1,),1), ((6,),12), ((12,),28), ((36,),91)],
 'is_perfect': [((0,),0), ((1,),0), ((6,),1), ((28,),1), ((12,),0)],
 'digit_sum': [((0,),0), ((12345,),15), ((909,),18), ((1000,),1)],
 'digit_product': [((0,),0), ((1234,),24), ((102,),0), ((99,),81)],
 'digit_count': [((0,),1), ((9,),1), ((10,),2), ((10000,),5)],
 'reverse_digits': [((0,),0), ((12345,),54321), ((1200,),21), ((7,),7)],
 'is_palindrome': [((0,),1), ((1221,),1), ((123,),0), ((101,),1)],
 'digital_root': [((0,),0), ((999,),9), ((12345,),6), ((8,),8)],
 'is_harshad': [((0,),0), ((18,),1), ((19,),0), ((100,),1)],
 'collatz_steps': [((1,),0), ((2,),1), ((6,),8), ((27,),111)],
 'integer_sqrt': [((0,),0), ((1,),1), ((15,),3), ((16,),4), ((1000000,),1000)],
 'ceil_div': [((0,3),0), ((10,3),4), ((12,3),4), ((1,9),1)],
 'binomial': [((5,2),10), ((0,0),1), ((6,7),0), ((10,5),252)],
 'population_count': [((0,),0), ((15,),4), ((16,),1), ((255,),8)],
 'binary_length': [((0,),0), ((1,),1), ((8,),4), ((255,),8)],
 'reverse_bits': [((13,4),11), ((1,8),128), ((0,8),0), ((15,4),15)],
 'trailing_zero_bits': [((0,),-1), ((1,),0), ((40,),3), ((64,),6)],
 'next_power_of_two': [((0,),1), ((1,),1), ((9,),16), ((64,),64)],
 'is_power_of_two': [((0,),0), ((1,),1), ((12,),0), ((64,),1)],
 'gray_encode': [((0,),0), ((1,),1), ((7,),4), ((10,),15)],
 'gray_decode': [((0,),0), ((1,),1), ((4,),7), ((15,),10)],
 'totient': [((1,),1), ((9,),6), ((12,),4), ((97,),96)],
 'largest_prime_factor': [((1,),1), ((12,),3), ((49,),7), ((97,),97)],
 'prime_factor_count': [((1,),0), ((12,),3), ((49,),2), ((97,),1)],
 'josephus': [((1,3),0), ((7,3),3), ((5,2),2), ((10,1),9)],
 'bounded_coin_count': [((0,),1), ((5,),2), ((10,),4), ((25,),13)],
 'greedy_coin_count': [((0,),0), ((30,),2), ((41,),4), ((99,),9)],
 'nth_prime': [((1,),2), ((2,),3), ((10,),29), ((25,),97)],
 'primes_below': [((2,),0), ((3,),1), ((10,),4), ((100,),25)],
 'sum_of_squares': [((0,),0), ((1,),1), ((5,),55), ((10,),385)],
 'sum_of_cubes': [((0,),0), ((1,),1), ((5,),225), ((10,),3025)],
 'triangular_index': [((0,),0), ((1,),1), ((15,),5), ((14,),-1)],
 'is_leap_year': [((1900,),0), ((2000,),1), ((2024,),1), ((2023,),0)],
 'days_in_month': [((1900,2),28), ((2000,2),29), ((2024,4),30), ((2024,1),31)],
 'clamp': [((2,5,10),5), ((7,5,10),7), ((12,5,10),10), ((5,5,5),5)],
 'median_three': [((3,1,2),2), ((9,9,1),9), ((1,2,3),2), ((3,2,1),2)],
 'integer_log': [((1,2),0), ((8,2),3), ((99,10),1), ((100,10),2)],
 'multiply_mod': [((12,13,7),2), ((0,9,3),0), ((123,456,97),22), ((5,9,1),0)],
 'fibonacci_mod': [((0,7),0), ((10,7),6), ((20,10),5), ((3,1),0)],
 'catalan': [((0,),1), ((1,),1), ((5,),42), ((8,),1430)],
 'derangements': [((0,),1), ((1,),0), ((4,),9), ((6,),265)],
 'lucas': [((0,),2), ((1,),1), ((5,),11), ((10,),123)],
 'pell': [((0,),0), ((1,),1), ((5,),29), ((10,),2378)],
 'mobius': [((1,),1), ((6,),1), ((12,),0), ((30,),-1)],
 'is_square_free': [((1,),1), ((6,),1), ((12,),0), ((49,),0)],
 'is_smooth': [((1,5),1), ((60,5),1), ((77,5),0), ((49,7),1)],
 'is_happy': [((1,),1), ((19,),1), ((2,),0), ((0,),0)],
 'is_armstrong': [((0,),1), ((153,),1), ((9474,),1), ((154,),0)],
 'is_automorphic': [((0,),1), ((25,),1), ((76,),1), ((12,),0)],
 'multiplicative_persistence': [((7,),0), ((39,),3), ((77,),4), ((10,),1)],
 'additive_persistence': [((0,),0), ((9,),0), ((999,),2), ((199,),3)],
 'count_digit': [((0,0),1), ((0,1),0), ((1001,0),2), ((777,7),3)],
 'rotate_decimal': [((0,),0), ((7,),7), ((1234,),4123), ((120,),12)],
 'base_digit_sum': [((15,2),4), ((255,16),30), ((100,10),1), ((0,3),0)],
 'factorial_zeros': [((0,),0), ((5,),1), ((25,),6), ((100,),24)],
 'pascal_row_sum': [((0,),1), ((1,),2), ((5,),32), ((10,),1024)],
 'lattice_paths': [((0,0),1), ((2,2),6), ((3,2),10), ((4,4),70)],
 'rectangle_count': [((0,4),0), ((1,1),1), ((2,3),18), ((4,4),100)],
 'square_count': [((0,),0), ((1,),1), ((3,),14), ((5,),55)],
 'digit_factorial_sum': [((0,),1), ((145,),145), ((123,),9), ((40585,),40585)],
 'happy_steps': [((1,),0), ((19,),4), ((2,),-1), ((0,),-1)],
 'discrete_log': [((2,1,7),0), ((2,4,7),2), ((2,3,7),-1), ((3,5,7),5)],
 'modular_inverse': [((3,7),5), ((2,4),-1), ((1,5),1), ((7,11),8)],
 'is_abundant': [((1,),0), ((6,),0), ((12,),1), ((18,),1)],
 'aliquot_sum': [((1,),0), ((6,),6), ((12,),16), ((28,),28)],
}

CONTRACTS = {
 'gcd': 'a,b >= 0; gcd(0,0) is defined as 0.',
 'lcm': 'a,b >= 0; zero arguments produce 0.',
 'factorial': '0 <= n <= 12; larger values exceed CMD signed 32-bit arithmetic.',
 'power': 'base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.',
 'modular_power': 'base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.',
 'integer_sqrt': '0 <= n <= 1000000; returns floor(sqrt(n)); division avoids square overflow.',
 'ceil_div': 'numerator >= 0; denominator > 0.',
 'josephus': 'n >= 1; step >= 1; result is a zero-based survivor index.',
 'integer_log': 'n >= 1; base >= 2; returns floor(log_base(n)).',
 'is_smooth': 'n >= 1; bound >= 2.',
 'totient': 'n >= 1.',
 'largest_prime_factor': 'n >= 1; returns 1 for the empty factorization of 1.',
 'prime_factor_count': 'n >= 1; counts prime factors with multiplicity.',
 'is_square_free': 'n >= 1.',
 'mobius': 'n >= 1; returns -1, 0 or 1.',
 'nth_prime': '1 <= index <= 100; trial division is intended for small inputs.',
 'is_happy': 'n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.',
 'happy_steps': 'n >= 0; returns -1 if no 1 is reached within 100 iterations.',
 'discrete_log': 'base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.',
 'modular_inverse': 'a >= 0; modulus > 1; returns -1 when no inverse exists.',
 'multiply_mod': 'a,b >= 0; 0 < modulus <= 1000000; repeated doubling avoids a*b overflow.',
 'fibonacci_mod': 'n >= 0; 0 < modulus <= 1000000.',
 'count_digit': 'n >= 0; 0 <= target <= 9; zero has one decimal digit.',
 'reverse_bits': 'n >= 0; 0 <= width <= 30; reads only the low width bits.',
 'trailing_zero_bits': 'n >= 0; zero returns -1 because it has no finite trailing-zero count.',
 'clamp': '0 <= low <= high; value >= 0.',
 'days_in_month': 'year >= 1; 1 <= month <= 12; proleptic Gregorian calendar.',
 'is_leap_year': 'year >= 1; proleptic Gregorian calendar.',
 'bounded_coin_count': '0 <= amount <= 1000; counts combinations of unlimited 1,5,10,25 coins.',
 'greedy_coin_count': 'amount >= 0; minimum number of US 1,5,10,25 coins.',
 'base_digit_sum': 'n >= 0; base >= 2.',
 'collatz_steps': '1 <= n <= 1000; demonstration only; no general termination claim.',
}
