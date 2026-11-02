#!/usr/bin/env bash
set -euo pipefail
# Totient.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: n >= 1.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

totient() {
    local v_n="${1:?missing argument}"
    local v_prime=0 v_remaining=0 v_result=0
    v_result=$(( v_n ))
    v_prime=$(( 2 ))
    v_remaining=$(( v_n ))
    while (( v_prime <= (v_remaining / v_prime) )); do
        if (( (v_remaining % v_prime) == 0 )); then
            while (( (v_remaining % v_prime) == 0 )); do
                v_remaining=$(( (v_remaining / v_prime) ))
            done
            v_result=$(( (v_result - (v_result / v_prime)) ))
        fi
        v_prime=$(( (v_prime + 1) ))
    done
    if (( v_remaining > 1 )); then
        v_result=$(( (v_result - (v_result / v_remaining)) ))
    fi
    REPLY=$(( v_result ))
    return 0
}

totient 1
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'totient fixture 1: (1,) -> 1' "$REPLY" >&2
    exit 1
fi
totient 9
if (( REPLY != 6 )); then
    printf '%s; got %s\n' 'totient fixture 2: (9,) -> 6' "$REPLY" >&2
    exit 1
fi
totient 12
if (( REPLY != 4 )); then
    printf '%s; got %s\n' 'totient fixture 3: (12,) -> 4' "$REPLY" >&2
    exit 1
fi
totient 97
if (( REPLY != 96 )); then
    printf '%s; got %s\n' 'totient fixture 4: (97,) -> 96' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'totient: 4 fixtures passed'
