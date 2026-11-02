#!/usr/bin/env bash
set -euo pipefail
# Digit sum.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

digit_sum() {
    local v_n="${1:?missing argument}"
    local v_total=0
    v_total=$(( 0 ))
    while (( v_n > 0 )); do
        v_total=$(( (v_total + (v_n % 10)) ))
        v_n=$(( (v_n / 10) ))
    done
    REPLY=$(( v_total ))
    return 0
}

digit_sum 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'digit_sum fixture 1: (0,) -> 0' "$REPLY" >&2
    exit 1
fi
digit_sum 12345
if (( REPLY != 15 )); then
    printf '%s; got %s\n' 'digit_sum fixture 2: (12345,) -> 15' "$REPLY" >&2
    exit 1
fi
digit_sum 909
if (( REPLY != 18 )); then
    printf '%s; got %s\n' 'digit_sum fixture 3: (909,) -> 18' "$REPLY" >&2
    exit 1
fi
digit_sum 1000
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'digit_sum fixture 4: (1000,) -> 1' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'digit_sum: 4 fixtures passed'
