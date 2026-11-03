#!/usr/bin/env bash
# Bash 4.3+ (arrays and nameless local staging); no eval or external commands.
# Parse the given argument vector, publishing globals only after full validation.
# --count requires decimal 1..999, --tag may repeat (including empty values).
# -- ends option processing. Unknown dash-prefixed arguments are errors (64).
set -euo pipefail
COUNT=1
TAGS=()
FILES=()

parse_options() {
    local count=1 arg
    local -a tags=() files=()
    while (( $# )); do
        arg=$1
        shift
        case $arg in
            --count)
                if (( $# == 0 )); then return 64; fi
                # Match spelling before arithmetic; reject octal-looking inputs.
                if [[ ! $1 =~ ^[1-9][0-9]{0,2}$ ]]; then return 64; fi
                count=$1; shift ;;
            --tag)
                if (( $# == 0 )); then return 64; fi
                tags+=("$1"); shift ;;
            --) files+=("$@"); break ;;
            -*) return 64 ;;
            *) files+=("$arg") ;;
        esac
    done
    COUNT=$count
    TAGS=("${tags[@]}")
    FILES=("${files[@]}")
}

check() { if ! "$@"; then printf 'check failed: %s\n' "$*" >&2; exit 1; fi; }
parse_options --count 999 --tag 'blue ink' --tag '' 'a file.txt' '*.csv' -- '-odd' ''
check test "$COUNT" = 999
check test "${#TAGS[@]}" = 2
check test "${TAGS[0]}" = 'blue ink'
check test "${TAGS[1]}" = ''
check test "${#FILES[@]}" = 4
check test "${FILES[0]}" = 'a file.txt'
check test "${FILES[1]}" = '*.csv'
check test "${FILES[2]}" = '-odd'
check test "${FILES[3]}" = ''

reject() {
    local status=0
    if parse_options "$@"; then
        printf 'accepted malformed arguments\n' >&2; exit 1
    else status=$?; fi
    check test "$status" = 64
    # Even a valid prefix must not partially overwrite previously published state.
    check test "$COUNT" = 999
    check test "${#TAGS[@]}" = 2
    check test "${TAGS[0]}" = 'blue ink'
    check test "${#FILES[@]}" = 4
    check test "${FILES[1]}" = '*.csv'
}
reject --count
reject --tag
reject --count 0
reject --count 01
reject --count 1000
reject --count '-1'
reject --count '1+2'
reject --count $'2\n'
reject --tag changed --count 2 --unknown
reject --count 2 partial-file --tag changed --tag
parse_options --count 1 --count 7 --tag '--literal-value' -- --count 4
check test "$COUNT" = 7
check test "${TAGS[0]}" = '--literal-value'
check test "${FILES[0]}" = '--count'
check test "${FILES[1]}" = 4
parse_options
check test "$COUNT" = 1
check test "${#TAGS[@]}" = 0
check test "${#FILES[@]}" = 0
printf 'Bash argument vector: quoting, option boundaries, statuses and transactional publication passed\n'
