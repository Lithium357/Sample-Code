#!/usr/bin/env bash
# Strict CSV parser with quoted newlines, escaped quotes, CRLF and atomic output.
# bash csv_state_machine.sh
# No eval, external processes, temporary files or separator-based serialization.
# Bash cannot represent NUL bytes; inputs are text without NUL. LC_ALL=C makes
# error offsets byte-based. Bare CR outside a quoted field is rejected.
set -euo pipefail
export LC_ALL=C
declare -a CSV_CELLS=() CSV_OFFSETS=() CSV_WIDTHS=()
CSV_ERROR=''

csv_parse() {
    local input=$1 expected=${2:-0} state=start field='' ch next
    local i=0 row_start=0 width=0 pending=0 end_record=0
    local -a cells=() offsets=() widths=()
    CSV_ERROR=''
    while (( i < ${#input} )); do
        ch=${input:i:1}; end_record=0
        if [[ $state == quoted ]]; then
            if [[ $ch == '"' ]]; then state=after_quote
            else field+=$ch
            fi
            i=$((i+1)); pending=1
            continue
        fi
        if [[ $state == after_quote && $ch == '"' ]]; then
            field+='"'; state=quoted; i=$((i+1)); continue
        fi
        if [[ $ch == $'\r' ]]; then
            next=${input:i+1:1}
            if [[ $next != $'\n' ]]; then CSV_ERROR="bare CR at byte $i"; return 1; fi
            i=$((i+1)); ch=$'\n'
        fi
        if [[ $ch == ',' || $ch == $'\n' ]]; then
            cells+=("$field"); field=''; width=$((width+1)); state=start
            if [[ $ch == $'\n' ]]; then end_record=1; else pending=1; fi
        elif [[ $state == after_quote ]]; then
            CSV_ERROR="unexpected character after closing quote at byte $i"; return 1
        elif [[ $ch == '"' ]]; then
            if [[ $state != start ]]; then CSV_ERROR="quote inside unquoted field at byte $i"; return 1; fi
            state=quoted; pending=1
        else
            field+=$ch; state=unquoted; pending=1
        fi
        if (( end_record )); then
            if (( expected > 0 && width != expected )); then CSV_ERROR="wrong field count in row ${#offsets[@]}"; return 1; fi
            offsets+=("$row_start"); widths+=("$width")
            row_start=${#cells[@]}; width=0; pending=0
        fi
        i=$((i+1))
    done
    if [[ $state == quoted ]]; then CSV_ERROR='unterminated quoted field'; return 1; fi
    if (( pending )); then
        cells+=("$field"); width=$((width+1))
        if (( expected > 0 && width != expected )); then CSV_ERROR="wrong field count in final row"; return 1; fi
        offsets+=("$row_start"); widths+=("$width")
    fi
    # Publish only after the complete input passes all validation.
    CSV_CELLS=("${cells[@]}"); CSV_OFFSETS=("${offsets[@]}"); CSV_WIDTHS=("${widths[@]}")
}

CSV_TEXT=''
csv_encode() {
    local row col cell escaped output='' delimiter
    for ((row=0; row<${#CSV_OFFSETS[@]}; row++)); do
        delimiter=''
        for ((col=0; col<CSV_WIDTHS[row]; col++)); do
            cell=${CSV_CELLS[CSV_OFFSETS[row]+col]}
            if [[ $cell == *','* || $cell == *'"'* || $cell == *$'\r'* || $cell == *$'\n'* || -z $cell ]]; then
                escaped=${cell//\"/\"\"}
                output+="$delimiter\"$escaped\""
            else output+="$delimiter$cell"
            fi
            delimiter=','
        done
        output+=$'\r\n'
    done
    CSV_TEXT=$output
}

assert_equal() { if [[ $1 != "$2" ]]; then printf 'expected <%s>, got <%s>\n' "$2" "$1" >&2; exit 1; fi; }
csv_parse $'name,note\r\nAda,"line one\nline two"\r\nBob,"say ""hi"""\r\n' 2
assert_equal "${#CSV_OFFSETS[@]}" 3
assert_equal "${CSV_CELLS[3]}" $'line one\nline two'
assert_equal "${CSV_CELLS[5]}" 'say "hi"'
before=("${CSV_CELLS[@]}")
for invalid in 'a"b,c' '"unterminated' '"a"x,b' $'a\rb'; do
    if csv_parse "$invalid"; then printf 'accepted invalid CSV\n' >&2; exit 1; fi
    assert_equal "${CSV_CELLS[5]}" "${before[5]}"
done
csv_parse ''; assert_equal "${#CSV_OFFSETS[@]}" 0
csv_parse $'\n'; assert_equal "${#CSV_CELLS[@]}" 1
csv_parse 'a,' 2; assert_equal "${CSV_CELLS[1]}" ''
if csv_parse $'a,b\nc' 2; then printf 'accepted ragged rows\n' >&2; exit 1; fi

# Round-trip arbitrary delimiter/quote/newline combinations without flattening
# field arrays into a lossy delimiter-separated intermediate string.
samples=('' alpha 'a,b' 'a"b' $'a\nb' $'a\r\nb' '  spaced  ')
for first in "${samples[@]}"; do
    for second in "${samples[@]}"; do
        CSV_CELLS=("$first" "$second"); CSV_OFFSETS=(0); CSV_WIDTHS=(2)
        csv_encode
        csv_parse "$CSV_TEXT" 2
        assert_equal "${CSV_CELLS[0]}" "$first"
        assert_equal "${CSV_CELLS[1]}" "$second"
    done
done
printf '%s\n' 'CSV parser: strict errors, atomic publication, multiline and 49 round trips passed'
