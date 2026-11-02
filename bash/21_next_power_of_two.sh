#!/usr/bin/env bash
set -euo pipefail
# Next power of two.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

next_power_of_two() {
    local v_n="${1:?missing argument}"
    local v_result=0
    v_result=$(( 1 ))
    while (( v_result < v_n )); do
        v_result=$(( (v_result * 2) ))
    done
    REPLY=$(( v_result ))
    return 0
}

next_power_of_two 0
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'next_power_of_two fixture 1: (0,) -> 1' "$REPLY" >&2
    exit 1
fi
next_power_of_two 1
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'next_power_of_two fixture 2: (1,) -> 1' "$REPLY" >&2
    exit 1
fi
next_power_of_two 9
if (( REPLY != 16 )); then
    printf '%s; got %s\n' 'next_power_of_two fixture 3: (9,) -> 16' "$REPLY" >&2
    exit 1
fi
next_power_of_two 64
if (( REPLY != 64 )); then
    printf '%s; got %s\n' 'next_power_of_two fixture 4: (64,) -> 64' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'next_power_of_two: 4 fixtures passed'
