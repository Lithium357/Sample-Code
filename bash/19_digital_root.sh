#!/usr/bin/env bash
set -euo pipefail
# Digital root.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

digital_root() {
    local v_n="${1:?missing argument}"
    local v_total=0
    while (( v_n >= 10 )); do
        v_total=$(( 0 ))
        while (( v_n > 0 )); do
            v_total=$(( (v_total + (v_n % 10)) ))
            v_n=$(( (v_n / 10) ))
        done
        v_n=$(( v_total ))
    done
    REPLY=$(( v_n ))
    return 0
}

digital_root 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'digital_root fixture 1: (0,) -> 0' "$REPLY" >&2
    exit 1
fi
digital_root 999
if (( REPLY != 9 )); then
    printf '%s; got %s\n' 'digital_root fixture 2: (999,) -> 9' "$REPLY" >&2
    exit 1
fi
digital_root 12345
if (( REPLY != 6 )); then
    printf '%s; got %s\n' 'digital_root fixture 3: (12345,) -> 6' "$REPLY" >&2
    exit 1
fi
digital_root 8
if (( REPLY != 8 )); then
    printf '%s; got %s\n' 'digital_root fixture 4: (8,) -> 8' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'digital_root: 4 fixtures passed'
