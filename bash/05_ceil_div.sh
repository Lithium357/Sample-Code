#!/usr/bin/env bash
set -euo pipefail
# Ceil div.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: numerator >= 0; denominator > 0.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

ceil_div() {
    local v_numerator="${1:?missing argument}"
    local v_denominator="${2:?missing argument}"
    local v_quotient=0
    v_quotient=$(( (v_numerator / v_denominator) ))
    if (( (v_numerator % v_denominator) != 0 )); then
        v_quotient=$(( (v_quotient + 1) ))
    fi
    REPLY=$(( v_quotient ))
    return 0
}

ceil_div 0 3
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'ceil_div fixture 1: (0, 3) -> 0' "$REPLY" >&2
    exit 1
fi
ceil_div 10 3
if (( REPLY != 4 )); then
    printf '%s; got %s\n' 'ceil_div fixture 2: (10, 3) -> 4' "$REPLY" >&2
    exit 1
fi
ceil_div 12 3
if (( REPLY != 4 )); then
    printf '%s; got %s\n' 'ceil_div fixture 3: (12, 3) -> 4' "$REPLY" >&2
    exit 1
fi
ceil_div 1 9
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'ceil_div fixture 4: (1, 9) -> 1' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'ceil_div: 4 fixtures passed'
