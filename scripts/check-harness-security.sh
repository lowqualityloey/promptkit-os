#!/usr/bin/env bash
set -uo pipefail
export LC_ALL=C
root=${1:-.}
if [[ ! -d "$root" || -L "$root" ]]; then
    printf '%s\n' 'PREFLIGHT|INCOMPLETE|ROOT'
    exit 2
fi
root=$(builtin cd -- "$root" && pwd -P) || exit 2
script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || exit 2
findings=0
incomplete=0
report() {
    printf 'PREFLIGHT|%s|%s|%s\n' "$1" "$2" "$3"
    case "$1" in WARNING) findings=1 ;; INCOMPLETE) incomplete=1 ;; esac
}
for table in harness-security-paths.txt harness-security-rules.txt; do
    if [[ ! -r "$script_dir/$table" ]]; then report INCOMPLETE RULES .; exit 2; fi
done
printf '%s\n' 'PREFLIGHT|SCOPE|20 fixed paths; 65536 bytes per file; no recursive scan or credential validation'
# Git performs metadata queries only. Never traverse .git as content.
git_ready=0
if [[ -e "$root/.git" || -L "$root/.git" ]]; then
    if [[ ! -d "$root/.git" || -L "$root/.git" || -L "$root/.git/index" ]]; then
        report INCOMPLETE GIT_LAYOUT .
    elif ! command -v git >/dev/null 2>&1; then
        report INCOMPLETE GIT_UNAVAILABLE .
    else
        git_ready=1
        if [[ -e "$root/.git/index" ]]; then
            index_size=$(stat -c %s -- "$root/.git/index" 2>/dev/null || stat -f %z "$root/.git/index" 2>/dev/null) || index_size=4194305
            if [[ ! -f "$root/.git/index" || ! -r "$root/.git/index" || "$index_size" -gt 4194304 ]]; then
                report INCOMPLETE GIT_INDEX_LIMIT .
                git_ready=0
            fi
        fi
    fi
else
    printf '%s\n' 'PREFLIGHT|NOT_APPLICABLE|GIT_METADATA|.'
fi
local_git() {
    GIT_OPTIONAL_LOCKS=0 git --git-dir="$root/.git" --work-tree="$root" \
        -c core.fsmonitor=false "$@" 2>/dev/null
}
while IFS='|' read -r relative kind; do
    path="$root/$relative"
    parent=${relative%/*}
    if [[ "$parent" != "$relative" && -L "$root/$parent" ]]; then
        printf 'PREFLIGHT|INCOMPLETE|SYMLINK|%s\n' "$relative"
        incomplete=1
        continue
    fi
    if [[ -L "$path" ]]; then
        printf 'PREFLIGHT|INCOMPLETE|SYMLINK|%s\n' "$relative"
        incomplete=1
        continue
    fi
    if [[ "$kind" == sensitive && "$git_ready" == 1 ]]; then
        tracked_path=$(local_git ls-files -- "$relative")
        status=$?
        if [[ "$status" != 0 ]]; then report INCOMPLETE GIT_TRACKING "$relative"
        elif [[ -n "$tracked_path" ]]; then report WARNING TRACKED_SENSITIVE "$relative"; fi
        if [[ -e "$path" || -n "$tracked_path" ]]; then
            local_git check-ignore --no-index -q -- "$relative"
            status=$?
            case "$status" in
                0) : ;;
                1) report WARNING IGNORE_GAP "$relative" ;;
                *) report INCOMPLETE GIT_IGNORE "$relative" ;;
            esac
        fi
    fi
    [[ -e "$path" ]] || continue
    if [[ ! -f "$path" || ! -r "$path" ]]; then
        printf 'PREFLIGHT|INCOMPLETE|UNREADABLE_OR_SPECIAL|%s\n' "$relative"
        incomplete=1
        continue
    fi
    size=$(stat -c %s -- "$path" 2>/dev/null || stat -f %z "$path" 2>/dev/null) || { incomplete=1; continue; }
    if [[ "$size" -gt 65536 ]]; then
        printf 'PREFLIGHT|INCOMPLETE|SIZE_LIMIT|%s\n' "$relative"
        incomplete=1
        continue
    fi
    content=$(dd if="$path" bs=65537 count=1 2>/dev/null | tr -d '\000') || { report INCOMPLETE UNREADABLE_OR_SPECIAL "$relative"; continue; }
    bytes=$(dd if="$path" bs=65537 count=1 2>/dev/null | wc -c)
    nonnull=$(dd if="$path" bs=65537 count=1 2>/dev/null | tr -d '\000' | wc -c)
    if [[ "$bytes" -gt 65536 ]]; then report INCOMPLETE SIZE_LIMIT "$relative"; continue; fi
    if [[ "$bytes" != "$nonnull" ]]; then report INCOMPLETE UNSUPPORTED_ENCODING "$relative"; continue; fi
    content=$(printf '%s' "$content" | tr '\r\n\t' '   ')
    while IFS='|' read -r rule scope pattern; do
        [[ "$scope" == all || "$scope" == "$kind" ]] || continue
        if printf '%s' "$content" | grep -Eq -- "$pattern"; then report WARNING "$rule" "$relative"; fi
    done < "$script_dir/harness-security-rules.txt"
    unset content
done < "$script_dir/harness-security-paths.txt"
if [[ "$incomplete" -ne 0 ]]; then exit 2; fi
if [[ "$findings" -ne 0 ]]; then exit 1; fi
printf '%s\n' 'PREFLIGHT|NO_FINDINGS|FIXED_SCOPE_ONLY'
exit 0
