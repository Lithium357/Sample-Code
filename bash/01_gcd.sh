#!/usr/bin/env bash
set -euo pipefail
# Gcd.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: a,b >= 0; gcd(0,0) is defined as 0.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

gcd() {
    local v_a="${1:?missing argument}"
    local v_b="${2:?missing argument}"
    local v_remainder=0
    while (( v_b != 0 )); do
        v_remainder=$(( (v_a % v_b) ))
        v_a=$(( v_b ))
        v_b=$(( v_remainder ))
    done
    REPLY=$(( v_a ))
    return 0
}

gcd 48 18
if (( REPLY != 6 )); then
    printf '%s; got %s\n' 'gcd fixture 1: (48, 18) -> 6' "$REPLY" >&2
    exit 1
fi
gcd 0 7
if (( REPLY != 7 )); then
    printf '%s; got %s\n' 'gcd fixture 2: (0, 7) -> 7' "$REPLY" >&2
    exit 1
fi
gcd 7 0
if (( REPLY != 7 )); then
    printf '%s; got %s\n' 'gcd fixture 3: (7, 0) -> 7' "$REPLY" >&2
    exit 1
fi
gcd 0 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'gcd fixture 4: (0, 0) -> 0' "$REPLY" >&2
    exit 1
fi
gcd 35 64
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'gcd fixture 5: (35, 64) -> 1' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'gcd: 5 fixtures passed'
