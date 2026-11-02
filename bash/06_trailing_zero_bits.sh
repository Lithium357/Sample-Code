#!/usr/bin/env bash
set -euo pipefail
# Trailing zero bits.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: n >= 0; zero returns -1 because it has no finite trailing-zero count.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

trailing_zero_bits() {
    local v_n="${1:?missing argument}"
    local v_count=0
    if (( v_n == 0 )); then
        REPLY=$(( (-1) ))
        return 0
    fi
    v_count=$(( 0 ))
    while (( (v_n % 2) == 0 )); do
        v_count=$(( (v_count + 1) ))
        v_n=$(( (v_n / 2) ))
    done
    REPLY=$(( v_count ))
    return 0
}

trailing_zero_bits 0
if (( REPLY != -1 )); then
    printf '%s; got %s\n' 'trailing_zero_bits fixture 1: (0,) -> -1' "$REPLY" >&2
    exit 1
fi
trailing_zero_bits 1
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'trailing_zero_bits fixture 2: (1,) -> 0' "$REPLY" >&2
    exit 1
fi
trailing_zero_bits 40
if (( REPLY != 3 )); then
    printf '%s; got %s\n' 'trailing_zero_bits fixture 3: (40,) -> 3' "$REPLY" >&2
    exit 1
fi
trailing_zero_bits 64
if (( REPLY != 6 )); then
    printf '%s; got %s\n' 'trailing_zero_bits fixture 4: (64,) -> 6' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'trailing_zero_bits: 4 fixtures passed'
