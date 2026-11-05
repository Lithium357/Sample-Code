#!/usr/bin/env bash
# Bash 4.3+ and GNU coreutils (mktemp, mv -T, cmp, find). Not POSIX sh.
# Process substitution does not propagate producer failure through a read loop.
# This collector explicitly waits for its producer and publishes only when BOTH
# parsing and production succeed. Destination is replaced via a same-parent
# temporary file; durability and cross-platform rename atomicity are not claimed.
# Input: unique lowercase ASCII identifier keys, '=', opaque non-NUL values.
# LF separates records; an unterminated final record is accepted. Empty input
# is valid. Blank/malformed/duplicate records or >1000 records give status 65.
# A failed producer's status is preserved unless a consumer failure takes
# precedence. Output is key TAB value LF. Producer must be trusted and finite,
# and must not leave background descendants holding its stdout open.
set -euo pipefail

collect_records() (
    # Subshell keeps EXIT cleanup and temporary descriptors out of caller state.
    local destination=${1-}
    (( $# >= 2 )) && [[ -n $destination ]] || exit 64
    shift
    local temporary='' input='' producer_pid='' producer_status=0 consumer_status=0
    local line='' key='' value='' count=0
    local -A seen=()
    cleanup_collect() {
        local status=$1
        if [[ -n $input ]]; then exec {input}<&- || :; fi
        if [[ -n $producer_pid ]]; then wait "$producer_pid" || :; fi
        if [[ -n $temporary ]]; then rm -f -- "$temporary"; fi
        exit "$status"
    }
    trap 'cleanup_collect $?' EXIT
    temporary=$(mktemp -- "${destination}.tmp.XXXXXXXX") || exit 73
    exec {input}< <("$@") || exit 74
    producer_pid=$!                 # capture immediately, before any other job
    while IFS= read -r line <&"$input" || [[ -n $line ]]; do
        if [[ $line != *=* ]]; then consumer_status=65; break; fi
        key=${line%%=*}
        value=${line#*=}
        # Validation precedes associative-array indexing; no eval/word splitting.
        if [[ ! $key =~ ^[a-z][a-z0-9_]*$ ]]; then consumer_status=65; break; fi
        if [[ ${seen[$key]+yes} ]]; then consumer_status=65; break; fi
        (( count += 1 ))
        if (( count > 1000 )); then consumer_status=65; break; fi
        seen[$key]=1
        if ! printf '%s\t%s\n' "$key" "$value" >>"$temporary"; then
            consumer_status=74; break
        fi
    done
    # Close our read end BEFORE wait, so an early consumer failure cannot leave
    # a finite writer blocked on a full pipe. It may receive SIGPIPE; the
    # consumer error still takes precedence over that resulting producer status.
    exec {input}<&-
    input=''
    if wait "$producer_pid"; then producer_status=0; else producer_status=$?; fi
    producer_pid=''
    if (( consumer_status )); then exit "$consumer_status"; fi
    if (( producer_status )); then exit "$producer_status"; fi
    # -T rejects directory destinations instead of silently moving INTO them.
    mv -T -- "$temporary" "$destination" || exit 73
    temporary=''
)

check() { if ! "$@"; then printf 'check failed\n' >&2; exit 1; fi; }
base=$(pwd -P)
root=$(mktemp -d -- "$base/process records.XXXXXXXX")
root=$(cd -- "$root" && pwd -P)
cleanup_fixture() {
    local status=$?
    # Verify the resolved absolute target is the owned directory before delete.
    if [[ $root == "$base/process records."* && $root != "$base" ]]; then
        rm -rf -- "$root"
    else
        printf 'unexpected cleanup path\n' >&2
        exit 1
    fi
    exit "$status"
}
trap cleanup_fixture EXIT
caller_trap=$(trap -p EXIT)
check test -n "$caller_trap"
destination="$root/published [records] !.tsv"
expected="$root/expected.tsv"
before="$root/before.tsv"
diagnostic="$root/diagnostic.txt"
produce_valid() {
    printf '%s\n' 'alpha=value with spaces\backslash' 'beta='
    printf '%s' 'omega=contains=equals'
}
produce_empty() { return 0; }
produce_failed() { printf '%s\n' 'partial=must not publish'; return 23; }
produce_empty_failed() { return 37; }
produce_duplicate() { printf '%s\n' 'x=one' 'x=two'; }
produce_malformed() { printf '%s\n' 'not an assignment'; }
produce_blank() { printf '\n'; }
produce_bad_key() { printf '%s\n' 'a[$(not-code)]=value'; }
produce_both_failed() { printf '%s\n' '=invalid'; return 23; }
produce_after_bad() {
    printf '%s\n' '=invalid'
    # Far beyond pipe capacity if the reader fails to close before waiting.
    local i
    for ((i=0;i<100000;i++)); do printf 'unused%d=value\n' "$i" || return "$?"; done
}
produce_many() {
    local limit=$1 i
    for ((i=0;i<limit;i++)); do printf 'k%d=v\n' "$i"; done
}

collect_records "$destination" produce_valid
printf '%s\t%s\n' alpha 'value with spaces\backslash' beta '' omega 'contains=equals' >"$expected"
check cmp -s -- "$destination" "$expected"
check test "$(trap -p EXIT)" = "$caller_trap"

expect_failure() {
    local expected_status=$1 actual=0
    shift
    printf 'original bytes\r\n' >"$destination"
    cp -- "$destination" "$before"
    if collect_records "$destination" "$@" 2>"$diagnostic"; then actual=0; else actual=$?; fi
    if (( actual != expected_status )); then
        printf 'wrong producer/consumer status: expected %d got %d\n' "$expected_status" "$actual" >&2
        exit 1
    fi
    check cmp -s -- "$destination" "$before"
    check test -z "$(find "$root" -name '*.tmp.*' -print -quit)"
    check test "$(trap -p EXIT)" = "$caller_trap"
}
expect_failure 23 produce_failed
expect_failure 37 produce_empty_failed
expect_failure 65 produce_duplicate
expect_failure 65 produce_malformed
expect_failure 65 produce_blank
expect_failure 65 produce_bad_key
expect_failure 65 produce_both_failed
expect_failure 65 produce_after_bad
expect_failure 65 produce_many 1001
collect_records "$destination" produce_many 1000
check test "$(wc -l <"$destination")" -eq 1000
collect_records "$destination" produce_empty
check test -f "$destination"
check test ! -s "$destination"

# The argv vector is forwarded literally; data is never reparsed as shell code.
produce_argument() { printf 'literal=%s\n' "$1"; }
collect_records "$destination" produce_argument 'space * [glob] ! $HOME \ value'
printf '%s\t%s\n' literal 'space * [glob] ! $HOME \ value' >"$expected"
check cmp -s -- "$destination" "$expected"

directory="$root/existing directory"
mkdir -- "$directory"
status=0
if collect_records "$directory" produce_valid 2>"$diagnostic"; then status=0; else status=$?; fi
check test "$status" -eq 73
check test -z "$(find "$directory" -mindepth 1 -print -quit)"
check test -z "$(find "$root" -name '*.tmp.*' -print -quit)"
status=0
if collect_records "$root/missing parent/result" produce_valid 2>"$diagnostic"; then status=0; else status=$?; fi
check test "$status" -eq 73
status=0
if collect_records "$destination"; then status=0; else status=$?; fi
check test "$status" -eq 64
check test -z "$(jobs -pr)"         # every finite producer was waited/reaped
check test "$(trap -p EXIT)" = "$caller_trap"
printf 'checked process source: statuses, quoting, boundaries, wait and cleanup passed\n'
