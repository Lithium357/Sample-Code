#!/usr/bin/env bash
set -euo pipefail
# Largest prime factor.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: n >= 1; returns 1 for the empty factorization of 1.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

largest_prime_factor() {
    local v_n="${1:?missing argument}"
    local v_divisor=0 v_largest=0
    v_largest=$(( 1 ))
    v_divisor=$(( 2 ))
    while (( v_divisor <= (v_n / v_divisor) )); do
        while (( (v_n % v_divisor) == 0 )); do
            v_largest=$(( v_divisor ))
            v_n=$(( (v_n / v_divisor) ))
        done
        v_divisor=$(( (v_divisor + 1) ))
    done
    if (( v_n > 1 )); then
        v_largest=$(( v_n ))
    fi
    REPLY=$(( v_largest ))
    return 0
}

largest_prime_factor 1
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'largest_prime_factor fixture 1: (1,) -> 1' "$REPLY" >&2
    exit 1
fi
largest_prime_factor 12
if (( REPLY != 3 )); then
    printf '%s; got %s\n' 'largest_prime_factor fixture 2: (12,) -> 3' "$REPLY" >&2
    exit 1
fi
largest_prime_factor 49
if (( REPLY != 7 )); then
    printf '%s; got %s\n' 'largest_prime_factor fixture 3: (49,) -> 7' "$REPLY" >&2
    exit 1
fi
largest_prime_factor 97
if (( REPLY != 97 )); then
    printf '%s; got %s\n' 'largest_prime_factor fixture 4: (97,) -> 97' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'largest_prime_factor: 4 fixtures passed'
