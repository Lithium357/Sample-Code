#!/usr/bin/env bash
set -euo pipefail
# Modular power.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: base,exponent >= 0; modulus > 0; intermediate products must fit signed 32-bit.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

modular_power() {
    local v_base="${1:?missing argument}"
    local v_exponent="${2:?missing argument}"
    local v_modulus="${3:?missing argument}"
    local v_result=0
    v_result=$(( (1 % v_modulus) ))
    v_base=$(( (v_base % v_modulus) ))
    while (( v_exponent > 0 )); do
        if (( (v_exponent % 2) == 1 )); then
            v_result=$(( ((v_result * v_base) % v_modulus) ))
        fi
        v_exponent=$(( (v_exponent / 2) ))
        v_base=$(( ((v_base * v_base) % v_modulus) ))
    done
    REPLY=$(( v_result ))
    return 0
}

modular_power 2 10 1000
if (( REPLY != 24 )); then
    printf '%s; got %s\n' 'modular_power fixture 1: (2, 10, 1000) -> 24' "$REPLY" >&2
    exit 1
fi
modular_power 7 0 1
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'modular_power fixture 2: (7, 0, 1) -> 0' "$REPLY" >&2
    exit 1
fi
modular_power 3 4 7
if (( REPLY != 4 )); then
    printf '%s; got %s\n' 'modular_power fixture 3: (3, 4, 7) -> 4' "$REPLY" >&2
    exit 1
fi
modular_power 5 3 13
if (( REPLY != 8 )); then
    printf '%s; got %s\n' 'modular_power fixture 4: (5, 3, 13) -> 8' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'modular_power: 4 fixtures passed'
