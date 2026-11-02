#!/usr/bin/env bash
set -euo pipefail
# Lucas.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

lucas() {
    local v_n="${1:?missing argument}"
    local v_current=0 v_following=0 v_index=0 v_previous=0
    v_previous=$(( 2 ))
    v_current=$(( 1 ))
    v_index=$(( 0 ))
    while (( v_index < v_n )); do
        v_following=$(( (v_previous + v_current) ))
        v_previous=$(( v_current ))
        v_current=$(( v_following ))
        v_index=$(( (v_index + 1) ))
    done
    REPLY=$(( v_previous ))
    return 0
}

lucas 0
if (( REPLY != 2 )); then
    printf '%s; got %s\n' 'lucas fixture 1: (0,) -> 2' "$REPLY" >&2
    exit 1
fi
lucas 1
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'lucas fixture 2: (1,) -> 1' "$REPLY" >&2
    exit 1
fi
lucas 5
if (( REPLY != 11 )); then
    printf '%s; got %s\n' 'lucas fixture 3: (5,) -> 11' "$REPLY" >&2
    exit 1
fi
lucas 10
if (( REPLY != 123 )); then
    printf '%s; got %s\n' 'lucas fixture 4: (10,) -> 123' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'lucas: 4 fixtures passed'
