#!/usr/bin/env bash
set -euo pipefail
# Power.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: base,exponent >= 0; all intermediate products must fit signed 32-bit; 0^0 = 1.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

power() {
    local v_base="${1:?missing argument}"
    local v_exponent="${2:?missing argument}"
    local v_result=0
    v_result=$(( 1 ))
    while (( v_exponent > 0 )); do
        if (( (v_exponent % 2) == 1 )); then
            v_result=$(( (v_result * v_base) ))
        fi
        v_exponent=$(( (v_exponent / 2) ))
        if (( v_exponent > 0 )); then
            v_base=$(( (v_base * v_base) ))
        fi
    done
    REPLY=$(( v_result ))
    return 0
}

power 0 0
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'power fixture 1: (0, 0) -> 1' "$REPLY" >&2
    exit 1
fi
power 2 10
if (( REPLY != 1024 )); then
    printf '%s; got %s\n' 'power fixture 2: (2, 10) -> 1024' "$REPLY" >&2
    exit 1
fi
power 3 5
if (( REPLY != 243 )); then
    printf '%s; got %s\n' 'power fixture 3: (3, 5) -> 243' "$REPLY" >&2
    exit 1
fi
power 7 1
if (( REPLY != 7 )); then
    printf '%s; got %s\n' 'power fixture 4: (7, 1) -> 7' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'power: 4 fixtures passed'
