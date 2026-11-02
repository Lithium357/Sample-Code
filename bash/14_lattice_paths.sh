#!/usr/bin/env bash
set -euo pipefail
# Lattice paths.
# Bash 4+; bash FILE.sh; integer arithmetic
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.
# REPLY carries the result; functions return shell status 0 on success.
REPLY=0

lattice_paths() {
    local v_width="${1:?missing argument}"
    local v_height="${2:?missing argument}"
    local v_index=0 v_result=0 v_steps=0
    v_steps=$(( (v_width + v_height) ))
    v_result=$(( 1 ))
    v_index=$(( 1 ))
    while (( v_index <= v_width )); do
        v_result=$(( ((v_result * ((v_steps - v_width) + v_index)) / v_index) ))
        v_index=$(( (v_index + 1) ))
    done
    REPLY=$(( v_result ))
    return 0
}

lattice_paths 0 0
if (( REPLY != 1 )); then
    printf '%s; got %s\n' 'lattice_paths fixture 1: (0, 0) -> 1' "$REPLY" >&2
    exit 1
fi
lattice_paths 2 2
if (( REPLY != 6 )); then
    printf '%s; got %s\n' 'lattice_paths fixture 2: (2, 2) -> 6' "$REPLY" >&2
    exit 1
fi
lattice_paths 3 2
if (( REPLY != 10 )); then
    printf '%s; got %s\n' 'lattice_paths fixture 3: (3, 2) -> 10' "$REPLY" >&2
    exit 1
fi
lattice_paths 4 4
if (( REPLY != 70 )); then
    printf '%s; got %s\n' 'lattice_paths fixture 4: (4, 4) -> 70' "$REPLY" >&2
    exit 1
fi
printf '%s\n' 'lattice_paths: 4 fixtures passed'
