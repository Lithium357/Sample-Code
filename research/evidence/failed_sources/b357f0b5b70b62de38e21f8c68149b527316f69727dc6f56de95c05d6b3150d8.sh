#!/usr/bin/env bash
# Bash 4.3+: dynamic descriptors, argv forwarding and callback exit statuses.
# bash descriptor_scope.sh; GNU mktemp for the owned local fixture directory.
# Callback borrows the final-argument descriptor and returns normally. It must
# not close/rebind it or exec/exit the shell. This is not asynchronous cancellation.
# Text fixtures are LF-delimited without NUL; final unterminated lines are kept.
set -euo pipefail
with_input() {
    if (( $# < 2 )); then return 64; fi
    local input_path=$1 descriptor result
    shift
    if [[ ! -f $input_path ]]; then return 66; fi
    if exec {descriptor}<"$input_path"; then :; else return 66; fi
    if "$@" "$descriptor"; then result=0; else result=$?; fi
    exec {descriptor}<&-
    return "$result"
}
check() { if ! "$@"; then printf 'check failed: %s\n' "$*" >&2; exit 1; fi; }
assert_closed() {
    if { : <&"$LAST_BORROWED"; } 2>/dev/null; then
        printf 'borrowed descriptor leaked\n' >&2; exit 1
    fi
}
REPLY=()
LAST_BORROWED=0
consume_lines() {
    local line='' borrowed=$1
    LAST_BORROWED=$borrowed
    REPLY=()
    while IFS= read -r -u "$borrowed" line || [[ -n $line ]]; do REPLY+=("$line"); done
    return 0
}
reject_after_one() {
    LAST_BORROWED=$1
    IFS= read -r -u "$1" FIRST_LINE
    return 23
}
inspect_arguments() {
    check test "$#" = 3
    check test "$1" = 'two words'
    check test "$2" = '*'
    LAST_BORROWED=$3
    return 0
}

fixture_parent=$(pwd -P)
fixture_root=$(mktemp -d "$fixture_parent/descriptor-fixture.XXXXXX")
cleanup() {
    case $fixture_root in
        "$fixture_parent"/descriptor-fixture.*) rm -rf -- "$fixture_root" ;;
        *) printf 'refusing mismatched cleanup path\n' >&2; return 1 ;;
    esac
}
trap cleanup EXIT
input_file=$fixture_root/$'spaces ! [glob]\nname.txt'
printf '%s\n' ' first \value ' '' > "$input_file"
printf '%s' 'last without newline' >> "$input_file"
exec {caller_descriptor}<"$input_file"
with_input "$input_file" consume_lines
check test "${#REPLY[@]}" = 3
check test "${REPLY[0]}" = ' first \value '
check test "${REPLY[1]}" = ''
check test "${REPLY[2]}" = 'last without newline'
assert_closed
# A separate open must not consume or close the caller's existing descriptor.
check test -n "$caller_descriptor"
IFS= read -r -u "$caller_descriptor" caller_line
check test "$caller_line" = ' first \value '
exec {caller_descriptor}<&-

status=0
if with_input "$input_file" reject_after_one; then
    printf 'callback failure lost\n' >&2; exit 1
else status=$?; fi
check test "$status" = 23
check test "$FIRST_LINE" = ' first \value '
assert_closed
with_input "$input_file" inspect_arguments 'two words' '*'
assert_closed
: > "$fixture_root/empty"
with_input "$fixture_root/empty" consume_lines
check test "${#REPLY[@]}" = 0
assert_closed
printf '\n' > "$fixture_root/one empty line"
with_input "$fixture_root/one empty line" consume_lines
check test "${#REPLY[@]}" = 1
check test "${REPLY[0]}" = ''
assert_closed
for unavailable in "$fixture_root/missing" "$fixture_root"; do
    REPLY=('unchanged')
    if with_input "$unavailable" consume_lines; then exit 1; else status=$?; fi
    check test "$status" = 66
    check test "${REPLY[0]}" = unchanged
done
if with_input "$input_file"; then exit 1; else status=$?; fi
check test "$status" = 64
for ((i=0; i<20; i++)); do
    with_input "$fixture_root/empty" consume_lines
    assert_closed
done
printf 'Bash descriptors: literal paths/argv, independent offsets, unterminated lines, callback status and closure passed\n'
