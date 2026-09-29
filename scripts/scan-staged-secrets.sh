#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-.}
awk_bin=${PROMPTKIT_AWK:-awk}

if ! command -v "$awk_bin" >/dev/null 2>&1; then
    printf '%s\n' 'Staged secret scan could not run: AWK is unavailable.' >&2
    exit 2
fi

paths_file=$(mktemp "${TMPDIR:-/tmp}/promptkit-staged-paths.XXXXXX") || {
    printf '%s\n' 'Staged secret scan could not create its private path list.' >&2
    exit 2
}
trap 'rm -f -- "$paths_file"' EXIT

escape_redacted_path() {
    local safe_path=$1 match pattern
    local password_pattern="password[[:space:]]*[:=][[:space:]]*[\"'][^\"']+[\"']"
    local password_unquoted_pattern="password[[:space:]]*[:=][[:space:]]*[^[:space:]/\\\\]+"
    local -a sensitive_patterns=(
        'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY'
        'AKIA[0-9A-Z]+'
        'ghp_[A-Za-z0-9]+'
        'github_pat_[A-Za-z0-9_]+'
        'sk_live_[0-9a-zA-Z]+'
        'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
    )
    sensitive_patterns+=("$password_pattern" "$password_unquoted_pattern")

    for pattern in "${sensitive_patterns[@]}"; do
        while [[ $safe_path =~ $pattern ]]; do
            match=${BASH_REMATCH[0]}
            safe_path=${safe_path//"$match"/REDACTED}
        done
    done

    printf '%q' "$safe_path"
}

if ! git --literal-pathspecs -C "$repo_root" diff --cached --name-only --diff-filter=ACMRT -z >"$paths_file"; then
    printf '%s\n' 'Staged secret scan could not enumerate staged paths; stop before committing.' >&2
    exit 2
fi

scan_found=0
while IFS= read -r -d '' path; do
    if ! staged_diff=$(git --literal-pathspecs -C "$repo_root" diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path"); then
        printf '%s\n' 'Staged secret scan could not read a staged diff; stop before committing.' >&2
        exit 2
    fi

    while IFS= read -r diff_line; do
        case "$diff_line" in
            'Binary files '*" differ"|'GIT binary patch')
                printf '%s\n' 'Staged secret scan could not inspect a binary diff; stop before committing.' >&2
                exit 2
                ;;
        esac
    done <<< "$staged_diff"

    if ! detections=$(
        printf '%s\n' "$staged_diff" |
            "$awk_bin" -v q="'" '
                /^@@ / {
                    if (!match($0, /\+[0-9]+/)) {
                        exit 2
                    }
                    next_line = substr($0, RSTART + 1, RLENGTH - 1) + 0
                    in_hunk = 1
                    next
                }
                in_hunk && /^\+/ {
                    content = substr($0, 2)
                    if (content ~ /BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY/) {
                        printf "%d|private-key marker\n", next_line
                    }
                    if (content ~ /AKIA[0-9A-Z]+/) {
                        printf "%d|AWS access-key pattern\n", next_line
                    }
                    if (content ~ /ghp_[A-Za-z0-9]+/) {
                        printf "%d|GitHub token pattern\n", next_line
                    }
                    if (content ~ /github_pat_[A-Za-z0-9_]+/) {
                        printf "%d|GitHub fine-grained token pattern\n", next_line
                    }
                    if (content ~ /sk_live_[0-9a-zA-Z]+/) {
                        printf "%d|Stripe live-key pattern\n", next_line
                    }
                    if (content ~ /eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/) {
                        printf "%d|JWT-like token pattern\n", next_line
                    }
                    password_pattern = "password[[:space:]]*[:=][[:space:]]*[\"" q "][^\"" q "]+[\"" q "]"
                    if (content ~ password_pattern) {
                        printf "%d|password-assignment pattern\n", next_line
                    }
                    next_line++
                }
            '
    ); then
        printf '%s\n' 'Staged secret scan failed while checking additions; stop before committing.' >&2
        exit 2
    fi

    escaped_path=$(escape_redacted_path "$path")
    while IFS='|' read -r line_number category; do
        [[ -n "$line_number" ]] || continue
        printf 'Potential %s in staged additions: %s:%s (matching content suppressed).\n' \
            "$category" "$escaped_path" "$line_number"
        scan_found=1
    done <<< "$detections"
done <"$paths_file"

if ((scan_found)); then
    exit 1
fi
