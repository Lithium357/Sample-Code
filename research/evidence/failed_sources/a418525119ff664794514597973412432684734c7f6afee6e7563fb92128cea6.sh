#!/usr/bin/env bash
# Bash 5.2+ and local POSIX utilities. No user files are read or changed.
# Covers quoted paths, NUL-delimited filenames, pipefail and EXIT cleanup.
set -euo pipefail
if [[ ${1-} == --cleanup-probe ]]; then
    owned=$2
    mkdir -- "$owned"
    trap 'rm -f -- "$owned/payload"; rmdir -- "$owned"' EXIT
    printf 'fixture\n' > "$owned/payload"
    exit 23
fi
root=$(mktemp -d "${TMPDIR:-/tmp}/morderca files.XXXXXXXX")
trap 'rm -rf -- "$root"' EXIT
mkdir -- "$root/input"
printf 'alpha\n' > "$root/input/file with spaces.txt"
printf 'beta\n' > "$root/input/-leading-dash.txt"
printf 'gamma\n' > "$root/input/"$'line\nbreak.txt'
printf 'bang\n' > "$root/input/bang!name.txt"
count=0
# Process substitution preserves the counter in this shell. find output uses
# NUL separators because newline is a legal filename byte.
while IFS= read -r -d '' filename; do
    [[ -f $filename ]] || exit 1
    bytes=$(wc -c < "$filename")
    ((bytes>0)) || exit 1
    count=$((count+1))
done < <(find "$root/input" -type f -print0)
[[ $count == 4 ]] || exit 1
upstream_failure() { printf 'data\n'; return 7; }
status=0
if upstream_failure | cat > "$root/pipeline.txt"; then
    printf 'lost upstream failure\n' >&2; exit 1
else status=$?
fi
[[ $status == 7 && $(cat "$root/pipeline.txt") == data ]] || exit 1
if printf 'present\n' | grep '^missing$' > "$root/no match.txt"; then
    printf 'unexpected grep match\n' >&2; exit 1
else status=$?
fi
[[ $status == 1 && ! -s "$root/no match.txt" ]] || exit 1
status=0
if bash "${BASH_SOURCE[0]}" --cleanup-probe "$root/probe with spaces"; then
    printf 'probe should fail\n' >&2; exit 1
else status=$?
fi
[[ $status == 23 && ! -e "$root/probe with spaces" ]] || exit 1
printf '%s\n' 'Local files: spaced/newline filenames, pipeline statuses and failure-path traps passed'
