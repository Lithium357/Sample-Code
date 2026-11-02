#!/usr/bin/env bash
# SemVer 2.0 precedence without arithmetic conversion of unbounded components.
# bash semver_compare.sh
# Build metadata is validated but ignored in precedence. ASCII identifiers only.
# Comparison result is in REPLY (-1/0/1), not a shell failure status.
set -euo pipefail
export LC_ALL=C
REPLY=0
declare -a CORE=() PRE=()

numeric_compare() {
    local a=$1 b=$2
    if (( ${#a} < ${#b} )); then REPLY=-1
    elif (( ${#a} > ${#b} )); then REPLY=1
    elif [[ $a < $b ]]; then REPLY=-1
    elif [[ $a > $b ]]; then REPLY=1
    else REPLY=0
    fi
}
semver_parse() {
    local input=$1 base prerelease='' metadata='' component
    local -a core=() pre=() build=()
    [[ $input =~ ^[0-9A-Za-z.+-]+$ ]] || return 2
    if [[ $input == *'+'* ]]; then
        metadata=${input#*+}; input=${input%%+*}
        [[ -n $metadata && $metadata != *'+'* && $metadata != .* && $metadata != *. && $metadata != *'..'* ]] || return 2
        IFS=. read -r -a build <<< "$metadata"
        for component in "${build[@]}"; do [[ $component =~ ^[0-9A-Za-z-]+$ ]] || return 2; done
    fi
    if [[ $input == *'-'* ]]; then
        prerelease=${input#*-}; base=${input%%-*}
        [[ -n $prerelease && $prerelease != .* && $prerelease != *. && $prerelease != *'..'* ]] || return 2
        IFS=. read -r -a pre <<< "$prerelease"
        for component in "${pre[@]}"; do
            [[ $component =~ ^[0-9A-Za-z-]+$ ]] || return 2
            if [[ $component =~ ^[0-9]+$ && ${#component} -gt 1 && $component == 0* ]]; then return 2; fi
        done
    else base=$input
    fi
    [[ $base =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || return 2
    core=("${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}")
    CORE=("${core[@]}"); PRE=("${pre[@]}")
}
semver_compare() {
    local a=$1 b=$2 i first second
    semver_parse "$a" || return 2
    local -a acore=("${CORE[@]}") apre=("${PRE[@]}")
    semver_parse "$b" || return 2
    local -a bcore=("${CORE[@]}") bpre=("${PRE[@]}")
    for ((i=0;i<3;i++)); do
        numeric_compare "${acore[i]}" "${bcore[i]}"
        if (( REPLY != 0 )); then return 0; fi
    done
    if (( ${#apre[@]}==0 && ${#bpre[@]}==0 )); then REPLY=0; return 0; fi
    if (( ${#apre[@]}==0 )); then REPLY=1; return 0; fi
    if (( ${#bpre[@]}==0 )); then REPLY=-1; return 0; fi
    for ((i=0;i<${#apre[@]} && i<${#bpre[@]};i++)); do
        first=${apre[i]}; second=${bpre[i]}
        if [[ $first =~ ^[0-9]+$ && $second =~ ^[0-9]+$ ]]; then numeric_compare "$first" "$second"
        elif [[ $first =~ ^[0-9]+$ ]]; then REPLY=-1
        elif [[ $second =~ ^[0-9]+$ ]]; then REPLY=1
        elif [[ $first < $second ]]; then REPLY=-1
        elif [[ $first > $second ]]; then REPLY=1
        else REPLY=0
        fi
        if (( REPLY != 0 )); then return 0; fi
    done
    numeric_compare "${#apre[@]}" "${#bpre[@]}"
}

ordered=('1.0.0-alpha' '1.0.0-alpha.1' '1.0.0-alpha.beta' '1.0.0-beta' '1.0.0-beta.2' '1.0.0-beta.11' '1.0.0-rc.1' '1.0.0' '2.0.0')
for ((i=0;i<${#ordered[@]};i++)); do
    for ((j=0;j<${#ordered[@]};j++)); do
        semver_compare "${ordered[i]}" "${ordered[j]}"
        expected=0; if ((i<j)); then expected=-1; elif ((i>j)); then expected=1; fi
        if ((REPLY!=expected)); then printf 'precedence mismatch\n' >&2; exit 1; fi
    done
done
for invalid in '' '1' '1.2' '01.2.3' '1.2.3-' '1.2.3+' '1.2.3-a..b' '1.2.3-01' '1.2.3+a..b' 'v1.2.3' '1.2.3+bad!'; do
    if semver_parse "$invalid"; then printf 'accepted invalid SemVer: %s\n' "$invalid" >&2; exit 1; fi
done
semver_compare '1.2.3+001.a' '1.2.3+other'; (( REPLY==0 ))
semver_compare '999999999999999999999999999999.0.0' '1000000000000000000000000000000.0.0'; (( REPLY==-1 ))
semver_compare '1.0.0-999999999999999999999' '1.0.0-z'; (( REPLY==-1 ))
printf '%s\n' 'SemVer: precedence matrix, metadata, strict grammar and unbounded numeric identifiers passed'
