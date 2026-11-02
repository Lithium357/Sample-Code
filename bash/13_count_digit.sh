#!/usr/bin/env bash
set -euo pipefail
# Count digit.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: n >= 0; 0 <= target <= 9; zero has one decimal digit.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

count_digit() {
    local v_n="${1:?missing argument}"
    local v_target="${2:?missing argument}"
    local v_count=0
    if (( v_n == 0 )); then
        if (( v_target == 0 )); then
            REPLY=$(( 1 ))
            return 0
        fi
        REPLY=$(( 0 ))
        return 0
    fi
    v_count=$(( 0 ))
    while (( v_n > 0 )); do
        if (( (v_n % 10) == v_target )); then
            v_count=$(( (v_count + 1) ))
        fi
        v_n=$(( (v_n / 10) ))
    done
    REPLY=$(( v_count ))
    return 0
}

count_digit 0 0
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'count_digit fixture 1: (0, 0) -> 1' "$REPLY" >&2
    exit 1
fi
count_digit 0 1
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'count_digit fixture 2: (0, 1) -> 0' "$REPLY" >&2
    exit 1
fi
count_digit 1001 0
if (( REPLY != 2 )); then
    printf '%s; got %s\n' 'count_digit fixture 3: (1001, 0) -> 2' "$REPLY" >&2
    exit 1
fi
count_digit 777 7
if (( REPLY != 3 )); then
    printf '%s; got %s\n' 'count_digit fixture 4: (777, 7) -> 3' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'count_digit: 4 fixtures passed'
