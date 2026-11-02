#!/usr/bin/env bash
set -euo pipefail
# Is happy.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: n >= 0; a cap of 100 digit-square iterations detects failure for these bounded inputs.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

is_happy() {
    local v_n="${1:?missing argument}"
    local v_digit=0 v_steps=0 v_total=0
    v_steps=$(( 0 ))
    while (( v_steps < 100 )); do
        if (( v_n == 1 )); then
            REPLY=$(( 1 ))
            return 0
        fi
        v_total=$(( 0 ))
        while (( v_n > 0 )); do
            v_digit=$(( (v_n % 10) ))
            v_total=$(( (v_total + (v_digit * v_digit)) ))
            v_n=$(( (v_n / 10) ))
        done
        v_n=$(( v_total ))
        v_steps=$(( (v_steps + 1) ))
    done
    REPLY=$(( 0 ))
    return 0
}

is_happy 1
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_happy fixture 1: (1,) -> 1' "$REPLY" >&2
    exit 1
fi
is_happy 19
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_happy fixture 2: (19,) -> 1' "$REPLY" >&2
    exit 1
fi
is_happy 2
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'is_happy fixture 3: (2,) -> 0' "$REPLY" >&2
    exit 1
fi
is_happy 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'is_happy fixture 4: (0,) -> 0' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'is_happy: 4 fixtures passed'
