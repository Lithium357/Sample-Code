#!/usr/bin/env bash
set -euo pipefail
# Triangular index.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

triangular_index() {
    local v_n="${1:?missing argument}"
    local v_index=0 v_total=0
    v_total=$(( 0 ))
    v_index=$(( 0 ))
    while (( v_total < v_n )); do
        v_index=$(( (v_index + 1) ))
        v_total=$(( (v_total + v_index) ))
    done
    if (( v_total == v_n )); then
        REPLY=$(( v_index ))
        return 0
    fi
    REPLY=$(( (-1) ))
    return 0
}

triangular_index 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'triangular_index fixture 1: (0,) -> 0' "$REPLY" >&2
    exit 1
fi
triangular_index 1
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'triangular_index fixture 2: (1,) -> 1' "$REPLY" >&2
    exit 1
fi
triangular_index 15
if (( REPLY != 5 )); then
    printf '%s; got %s\n' 'triangular_index fixture 3: (15,) -> 5' "$REPLY" >&2
    exit 1
fi
triangular_index 14
if (( REPLY != -1 )); then
    printf '%s; got %s\n' 'triangular_index fixture 4: (14,) -> -1' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'triangular_index: 4 fixtures passed'
