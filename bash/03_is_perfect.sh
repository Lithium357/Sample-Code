#!/usr/bin/env bash
set -euo pipefail
# Is perfect.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

is_perfect() {
    local v_n="${1:?missing argument}"
    local v_divisor=0 v_total=0
    v_total=$(( 0 ))
    v_divisor=$(( 1 ))
    while (( v_divisor < v_n )); do
        if (( (v_n % v_divisor) == 0 )); then
            v_total=$(( (v_total + v_divisor) ))
        fi
        v_divisor=$(( (v_divisor + 1) ))
    done
    if (( v_total == v_n )); then
        if (( v_n > 0 )); then
            REPLY=$(( 1 ))
            return 0
        fi
    fi
    REPLY=$(( 0 ))
    return 0
}

is_perfect 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'is_perfect fixture 1: (0,) -> 0' "$REPLY" >&2
    exit 1
fi
is_perfect 1
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'is_perfect fixture 2: (1,) -> 0' "$REPLY" >&2
    exit 1
fi
is_perfect 6
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_perfect fixture 3: (6,) -> 1' "$REPLY" >&2
    exit 1
fi
is_perfect 28
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_perfect fixture 4: (28,) -> 1' "$REPLY" >&2
    exit 1
fi
is_perfect 12
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'is_perfect fixture 5: (12,) -> 0' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'is_perfect: 5 fixtures passed'
