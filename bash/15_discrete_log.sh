#!/usr/bin/env bash
set -euo pipefail
# Discrete log.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: base,target >= 0; modulus > 1; target < modulus; brute-force exponent search.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

discrete_log() {
    local v_base="${1:?missing argument}"
    local v_target="${2:?missing argument}"
    local v_modulus="${3:?missing argument}"
    local v_exponent=0 v_value=0
    v_value=$(( (1 % v_modulus) ))
    v_exponent=$(( 0 ))
    while (( v_exponent < v_modulus )); do
        if (( v_value == v_target )); then
            REPLY=$(( v_exponent ))
            return 0
        fi
        v_value=$(( ((v_value * v_base) % v_modulus) ))
        v_exponent=$(( (v_exponent + 1) ))
    done
    REPLY=$(( (-1) ))
    return 0
}

discrete_log 2 1 7
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'discrete_log fixture 1: (2, 1, 7) -> 0' "$REPLY" >&2
    exit 1
fi
discrete_log 2 4 7
if (( REPLY != 2 )); then
    printf '%s; got %s\n' 'discrete_log fixture 2: (2, 4, 7) -> 2' "$REPLY" >&2
    exit 1
fi
discrete_log 2 3 7
if (( REPLY != -1 )); then
    printf '%s; got %s\n' 'discrete_log fixture 3: (2, 3, 7) -> -1' "$REPLY" >&2
    exit 1
fi
discrete_log 3 5 7
if (( REPLY != 5 )); then
    printf '%s; got %s\n' 'discrete_log fixture 4: (3, 5, 7) -> 5' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'discrete_log: 4 fixtures passed'
