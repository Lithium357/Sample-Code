#!/usr/bin/env bash
set -euo pipefail
# Binomial.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

binomial() {
    local v_n="${1:?missing argument}"
    local v_k="${2:?missing argument}"
    local v_index=0 v_result=0
    if (( v_k > v_n )); then
        REPLY=$(( 0 ))
        return 0
    fi
    if (( v_k > (v_n - v_k) )); then
        v_k=$(( (v_n - v_k) ))
    fi
    v_result=$(( 1 ))
    v_index=$(( 1 ))
    while (( v_index <= v_k )); do
        v_result=$(( ((v_result * ((v_n - v_k) + v_index)) / v_index) ))
        v_index=$(( (v_index + 1) ))
    done
    REPLY=$(( v_result ))
    return 0
}

binomial 5 2
if (( REPLY != 10 )); then
    printf '%s; got %s\n' 'binomial fixture 1: (5, 2) -> 10' "$REPLY" >&2
    exit 1
fi
binomial 0 0
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'binomial fixture 2: (0, 0) -> 1' "$REPLY" >&2
    exit 1
fi
binomial 6 7
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'binomial fixture 3: (6, 7) -> 0' "$REPLY" >&2
    exit 1
fi
binomial 10 5
if (( REPLY != 252 )); then
    printf '%s; got %s\n' 'binomial fixture 4: (10, 5) -> 252' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'binomial: 4 fixtures passed'
