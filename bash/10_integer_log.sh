#!/usr/bin/env bash
set -euo pipefail
# Integer log.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: n >= 1; base >= 2; returns floor(log_base(n)).
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

integer_log() {
    local v_n="${1:?missing argument}"
    local v_base="${2:?missing argument}"
    local v_exponent=0
    v_exponent=$(( 0 ))
    while (( v_n >= v_base )); do
        v_n=$(( (v_n / v_base) ))
        v_exponent=$(( (v_exponent + 1) ))
    done
    REPLY=$(( v_exponent ))
    return 0
}

integer_log 1 2
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'integer_log fixture 1: (1, 2) -> 0' "$REPLY" >&2
    exit 1
fi
integer_log 8 2
if (( REPLY != 3 )); then
    printf '%s; got %s\n' 'integer_log fixture 2: (8, 2) -> 3' "$REPLY" >&2
    exit 1
fi
integer_log 99 10
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'integer_log fixture 3: (99, 10) -> 1' "$REPLY" >&2
    exit 1
fi
integer_log 100 10
if (( REPLY != 2 )); then
    printf '%s; got %s\n' 'integer_log fixture 4: (100, 10) -> 2' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'integer_log: 4 fixtures passed'
