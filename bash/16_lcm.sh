#!/usr/bin/env bash
set -euo pipefail
# Lcm.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: a,b >= 0; zero arguments produce 0.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

lcm() {
    local v_a="${1:?missing argument}"
    local v_b="${2:?missing argument}"
    local v_remainder=0 v_x=0 v_y=0
    if (( v_a == 0 )); then
        REPLY=$(( 0 ))
        return 0
    fi
    if (( v_b == 0 )); then
        REPLY=$(( 0 ))
        return 0
    fi
    v_x=$(( v_a ))
    v_y=$(( v_b ))
    while (( v_y != 0 )); do
        v_remainder=$(( (v_x % v_y) ))
        v_x=$(( v_y ))
        v_y=$(( v_remainder ))
    done
    REPLY=$(( ((v_a / v_x) * v_b) ))
    return 0
}

lcm 12 18
if (( REPLY != 36 )); then
    printf '%s; got %s\n' 'lcm fixture 1: (12, 18) -> 36' "$REPLY" >&2
    exit 1
fi
lcm 0 7
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'lcm fixture 2: (0, 7) -> 0' "$REPLY" >&2
    exit 1
fi
lcm 7 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'lcm fixture 3: (7, 0) -> 0' "$REPLY" >&2
    exit 1
fi
lcm 5 7
if (( REPLY != 35 )); then
    printf '%s; got %s\n' 'lcm fixture 4: (5, 7) -> 35' "$REPLY" >&2
    exit 1
fi
lcm 9 9
if (( REPLY != 9 )); then
    printf '%s; got %s\n' 'lcm fixture 5: (9, 9) -> 9' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'lcm: 5 fixtures passed'
