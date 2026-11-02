#!/usr/bin/env bash
# Nested transactions/savepoints using a reversible undo log; no eval or files.
# bash transactional_map.sh
# Keys are restricted ASCII identifiers. Values may contain arbitrary non-NUL
# text, including tabs and newlines. Bash 5.2+ nameref-free implementation.
set -euo pipefail
declare -A KV=()
declare -a TX_MARKS=() UNDO_KEYS=() UNDO_VALUES=() UNDO_EXISTS=()

valid_key() { [[ $1 =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; }
tx_begin() { TX_MARKS+=("${#UNDO_KEYS[@]}"); }
log_before() {
    local key=$1
    if (( ${#TX_MARKS[@]} == 0 )); then return 0; fi
    UNDO_KEYS+=("$key")
    if [[ ${KV[$key]+present} ]]; then
        UNDO_EXISTS+=(1); UNDO_VALUES+=("${KV[$key]}")
    else UNDO_EXISTS+=(0); UNDO_VALUES+=('')
    fi
}
map_put() {
    valid_key "$1" || return 2
    log_before "$1"; KV[$1]=$2
}
map_delete() {
    valid_key "$1" || return 2
    log_before "$1"
    local key=$1
    unset 'KV[$key]'
}
tx_commit() {
    local depth=${#TX_MARKS[@]}
    (( depth > 0 )) || return 2
    unset 'TX_MARKS[depth-1]'
    # Inner commit keeps its undo entries so an outer rollback can undo it.
    if (( depth == 1 )); then UNDO_KEYS=(); UNDO_VALUES=(); UNDO_EXISTS=(); fi
}
tx_rollback() {
    local depth=${#TX_MARKS[@]} index key mark
    (( depth > 0 )) || return 2
    mark=${TX_MARKS[depth-1]}
    for ((index=${#UNDO_KEYS[@]}-1; index>=mark; index--)); do
        key=${UNDO_KEYS[index]}
        if (( UNDO_EXISTS[index] )); then KV[$key]=${UNDO_VALUES[index]}
        else unset 'KV[$key]'
        fi
        unset 'UNDO_KEYS[index]' 'UNDO_VALUES[index]' 'UNDO_EXISTS[index]'
    done
    unset 'TX_MARKS[depth-1]'
}
assert() { if ! "$@"; then printf 'self-check failed\n' >&2; exit 1; fi; }
map_put original $'one\ntwo'
tx_begin
map_put original changed
tx_begin
map_delete original
map_put empty ''
tx_commit
assert test "${KV[empty]+yes}" = yes
tx_rollback
assert test "${KV[original]}" = $'one\ntwo'
assert test "${KV[empty]+yes}" = ''
tx_begin; map_put permanent retained; tx_commit
tx_begin; map_put permanent overwritten; tx_rollback
assert test "${KV[permanent]}" = retained
if tx_commit; then exit 1; fi
if tx_rollback; then exit 1; fi
if map_put 'bad key' value; then exit 1; fi
assert test "${#UNDO_KEYS[@]}" = 0

# Differential oracle: each savepoint takes a full copy in parallel associative
# arrays. This is intentionally a different, slower representation than undo logs.
KV=(); declare -A REF=() SAVED=() SAVED_PRESENT=()
depth=0; seed=53
for ((step=0;step<1000;step++)); do
    seed=$(((seed*251+17)%10007)); key=k$((seed%7)); operation=$((seed%5))
    case $operation in
        0)
            tx_begin; depth=$((depth+1))
            for ((i=0;i<7;i++)); do
                slot=$depth,k$i
                SAVED_PRESENT[$slot]=${REF[k$i]+yes}
                SAVED[$slot]=${REF[k$i]-}
            done
            ;;
        1)
            map_put "$key" "$step"; REF[$key]=$step
            ;;
        2)
            map_delete "$key"; unset 'REF[$key]'
            ;;
        3)
            if ((depth>0)); then
                tx_commit; depth=$((depth-1))
            fi
            ;;
        4)
            if ((depth>0)); then
                tx_rollback
                for ((i=0;i<7;i++)); do
                    slot=$depth,k$i; key=k$i
                    if [[ ${SAVED_PRESENT[$slot]} == yes ]]; then REF[$key]=${SAVED[$slot]}
                    else unset 'REF[$key]'
                    fi
                done
                depth=$((depth-1))
            fi
            ;;
    esac
    assert test "${#KV[@]}" = "${#REF[@]}"
    for ((i=0;i<7;i++)); do
        key=k$i
        assert test "${KV[$key]+yes}" = "${REF[$key]+yes}"
        assert test "${KV[$key]-}" = "${REF[$key]-}"
    done
done
while ((depth>0)); do tx_commit; depth=$((depth-1)); done
assert test "${#UNDO_KEYS[@]}" = 0
printf '%s\n' 'Transactional map: nested commit/rollback, empty values and 1000 snapshot comparisons passed'
