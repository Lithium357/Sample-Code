#!/usr/bin/env bash
set -euo pipefail
# Is palindrome.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

is_palindrome() {
    local v_n="${1:?missing argument}"
    local v_original=0 v_reversed_value=0
    v_original=$(( v_n ))
    v_reversed_value=$(( 0 ))
    while (( v_n > 0 )); do
        v_reversed_value=$(( ((v_reversed_value * 10) + (v_n % 10)) ))
        v_n=$(( (v_n / 10) ))
    done
    if (( v_reversed_value == v_original )); then
        REPLY=$(( 1 ))
        return 0
    fi
    REPLY=$(( 0 ))
    return 0
}

is_palindrome 0
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_palindrome fixture 1: (0,) -> 1' "$REPLY" >&2
    exit 1
fi
is_palindrome 1221
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_palindrome fixture 2: (1221,) -> 1' "$REPLY" >&2
    exit 1
fi
is_palindrome 123
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'is_palindrome fixture 3: (123,) -> 0' "$REPLY" >&2
    exit 1
fi
is_palindrome 101
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'is_palindrome fixture 4: (101,) -> 1' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'is_palindrome: 4 fixtures passed'
