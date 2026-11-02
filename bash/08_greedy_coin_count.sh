#!/usr/bin/env bash
set -euo pipefail
# Greedy coin count.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: amount >= 0; minimum number of US 1,5,10,25 coins.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

greedy_coin_count() {
    local v_amount="${1:?missing argument}"
    local v_count=0
    v_count=$(( (v_amount / 25) ))
    v_amount=$(( (v_amount % 25) ))
    v_count=$(( (v_count + (v_amount / 10)) ))
    v_amount=$(( (v_amount % 10) ))
    v_count=$(( (v_count + (v_amount / 5)) ))
    v_amount=$(( (v_amount % 5) ))
    REPLY=$(( (v_count + v_amount) ))
    return 0
}

greedy_coin_count 0
if (( REPLY != 0 )); then
    printf '%s; got %s\n' 'greedy_coin_count fixture 1: (0,) -> 0' "$REPLY" >&2
    exit 1
fi
greedy_coin_count 30
if (( REPLY != 2 )); then
    printf '%s; got %s\n' 'greedy_coin_count fixture 2: (30,) -> 2' "$REPLY" >&2
    exit 1
fi
greedy_coin_count 41
if (( REPLY != 4 )); then
    printf '%s; got %s\n' 'greedy_coin_count fixture 3: (41,) -> 4' "$REPLY" >&2
    exit 1
fi
greedy_coin_count 99
if (( REPLY != 9 )); then
    printf '%s; got %s\n' 'greedy_coin_count fixture 4: (99,) -> 9' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'greedy_coin_count: 4 fixtures passed'
