#!/usr/bin/env bash
set -euo pipefail

repo_root=${1:-.}
awk_bin=${PROMPTKIT_AWK:-awk}

if ! command -v "$awk_bin" >/dev/null 2>&1; then
    printf '%s\n' 'Staged secret scan could not run: AWK is unavailable.' >&2
    exit 2
fi

script_dir=$(builtin cd -- "$(dirname -- "$0")" && pwd -P) || {
    printf '%s\n' 'Staged secret scan could not resolve its script directory; stop before committing.' >&2
    exit 2
}

# Narrative-surface detectors and their allowlist are externalized data files
# modeled on scripts/harness-security-*.txt. A missing or unreadable file fails
# the scan closed (exit 2) exactly like check-harness-security.sh, so a
# half-installed kit cannot silently downgrade into a clean bill of health.
narrative_rules="$script_dir/narrative-surface-rules.txt"
narrative_paths="$script_dir/narrative-surface-paths.txt"
narrative_rules_extra=${PROMPTKIT_NARRATIVE_RULES_EXTRA:-}
narrative_paths_extra=${PROMPTKIT_NARRATIVE_PATHS_EXTRA:-}
if [[ ! -r "$narrative_rules" || ! -r "$narrative_paths" ]]; then
    printf '%s\n' 'Staged secret scan could not read its narrative-surface rules; stop before committing.' >&2
    exit 2
fi
if [[ -n "$narrative_rules_extra" && ! -r "$narrative_rules_extra" ]]; then
    printf '%s\n' 'Staged secret scan could not read its narrative-surface rules extension; stop before committing.' >&2
    exit 2
fi
if [[ -n "$narrative_paths_extra" && ! -r "$narrative_paths_extra" ]]; then
    printf '%s\n' 'Staged secret scan could not read its narrative-surface allowlist extension; stop before committing.' >&2
    exit 2
fi

# Strict row validation, fail closed, mirroring scripts/check-checkpoint-ignore.sh:
# a malformed row aborts before any diff is read, so a typo cannot silently narrow
# detector coverage. Exactly two pipes for rules (NAME|regex|severity), one for
# allowlist rows (glob|allow), with every field non-empty. A regex containing `|`
# therefore fails closed instead of being silently truncated at the separator.
validate_narrative_rules() {
    local table=$1 line name regex severity
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%$'\r'}
        [[ -n "$line" ]] || continue
        [[ "$line" == '#'* ]] && continue
        name=${line%%|*}
        regex=${line#*|}
        regex=${regex%%|*}
        severity=${line##*|}
        if [[ "${line//[!|]/}" != '||' || -z "$name" || -z "$regex" || -z "$severity" ]]; then
            printf '%s\n' 'Staged secret scan found a malformed narrative-surface rules row; stop before committing.' >&2
            exit 2
        fi
    done <"$table"
}

validate_narrative_paths() {
    local table=$1 line glob kind
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%$'\r'}
        [[ -n "$line" ]] || continue
        [[ "$line" == '#'* ]] && continue
        glob=${line%%|*}
        kind=${line#*|}
        if [[ "${line//[!|]/}" != '|' || -z "$glob" || "$kind" != allow ]]; then
            printf '%s\n' 'Staged secret scan found a malformed narrative-surface allowlist row; stop before committing.' >&2
            exit 2
        fi
    done <"$table"
}

validate_narrative_rules "$narrative_rules"
validate_narrative_paths "$narrative_paths"
if [[ -n "$narrative_rules_extra" ]]; then
    validate_narrative_rules "$narrative_rules_extra"
fi
if [[ -n "$narrative_paths_extra" ]]; then
    validate_narrative_paths "$narrative_paths_extra"
fi

paths_file=$(mktemp "${TMPDIR:-/tmp}/promptkit-staged-paths.XXXXXX" 2>/dev/null) || {
    printf '%s\n' 'Staged secret scan could not create its private path list.' >&2
    exit 2
}
trap 'rm -f -- "$paths_file" 2>/dev/null' EXIT

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
    # Extended issuer prefixes (kept in detection parity with the awk block).
    sensitive_patterns+=(
        'gho_[A-Za-z0-9]+'
        'ghu_[A-Za-z0-9]+'
        'ghs_[A-Za-z0-9]+'
        'ghr_[A-Za-z0-9]+'
        'xox[baprs]-[A-Za-z0-9-]+'
        'AIza[0-9A-Za-z_-]+'
    )

    for pattern in "${sensitive_patterns[@]}"; do
        while [[ $safe_path =~ $pattern ]]; do
            match=${BASH_REMATCH[0]}
            safe_path=${safe_path//"$match"/REDACTED}
        done
    done

    printf '%q' "$safe_path"
}

# A staged path is exempt from narrative-surface detection only when an `allow`
# glob in the allowlist matches it; secret detection still runs on every path.
is_narrative_allowed() {
    local candidate=$1 glob kind
    for table in "$narrative_paths" "$narrative_paths_extra"; do
        [[ -n "$table" ]] || continue
        while IFS='|' read -r glob kind; do
            [[ -n "$glob" ]] || continue
            [[ "$glob" == '#'* ]] && continue
            [[ "$kind" == allow ]] || continue
            # shellcheck disable=SC2254
            case "$candidate" in
                $glob) return 0 ;;
            esac
        done <"$table"
    done
    return 1
}

if ! git --literal-pathspecs -C "$repo_root" diff --cached --name-only --diff-filter=ACMRT -z >"$paths_file" 2>/dev/null; then
    printf '%s\n' 'Staged secret scan could not enumerate staged paths; stop before committing.' >&2
    exit 2
fi

scan_found=0
narrative_found=0
while IFS= read -r -d '' path; do
    if ! staged_diff=$(git --literal-pathspecs -C "$repo_root" diff --cached --no-ext-diff --no-textconv --unified=0 -- "$path" 2>/dev/null); then
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

    if is_narrative_allowed "$path"; then
        skip_narrative=1
    else
        skip_narrative=0
    fi

    if ! detections=$(
        printf '%s\n' "$staged_diff" |
            "$awk_bin" -v q="'" -v rules_file="$narrative_rules" \
                -v rules_extra="$narrative_rules_extra" -v skip_narrative="$skip_narrative" -f /dev/fd/3 3<<'AWK'
                BEGIN {
                    rule_count = 0
                    for (source_index = 0; source_index < 2; source_index++) {
                        source = (source_index == 0) ? rules_file : rules_extra
                        if (source == "") continue
                        while ((getline rule_line < source) > 0) {
                            if (rule_line == "" || rule_line ~ /^#/) continue
                            first = index(rule_line, "|")
                            if (first == 0) continue
                            remainder = substr(rule_line, first + 1)
                            second = index(remainder, "|")
                            if (second == 0) continue
                            rule_count++
                            rule_name[rule_count] = substr(rule_line, 1, first - 1)
                            rule_regex[rule_count] = substr(remainder, 1, second - 1)
                            rule_severity[rule_count] = substr(remainder, second + 1)
                        }
                        close(source)
                    }
                }
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
                    if (content ~ /gho_[A-Za-z0-9]+/) {
                        printf "%d|GitHub OAuth token pattern\n", next_line
                    }
                    if (content ~ /ghu_[A-Za-z0-9]+/) {
                        printf "%d|GitHub user token pattern\n", next_line
                    }
                    if (content ~ /ghs_[A-Za-z0-9]+/) {
                        printf "%d|GitHub server token pattern\n", next_line
                    }
                    if (content ~ /ghr_[A-Za-z0-9]+/) {
                        printf "%d|GitHub refresh token pattern\n", next_line
                    }
                    if (content ~ /xox[baprs]-[A-Za-z0-9-]+/) {
                        printf "%d|Slack token pattern\n", next_line
                    }
                    if (content ~ /AIza[0-9A-Za-z_-]+/) {
                        printf "%d|Google API key pattern\n", next_line
                    }
                    # Bare assignments with no quotes are just as exfiltrating;
                    # bracketed placeholders (e.g. <change-me>) stay silent.
                    password_hit = 0
                    password_pattern = "password[[:space:]]*[:=][[:space:]]*[\"" q "][^\"" q "]+[\"" q "]"
                    if (content ~ password_pattern) {
                        printf "%d|password-assignment pattern\n", next_line
                        password_hit = 1
                    }
                    password_bare = "password[[:space:]]*[:=][[:space:]]*[^[:space:]/\\\\\\042" q "\\042][^[:space:]]*"
                    if (match(content, password_bare)) {
                        password_val = substr(content, RSTART, RLENGTH)
                        sub(/^[^:=]*[:=][[:space:]]*/, "", password_val)
                        if (password_val !~ /^[<\[]/) {
                            printf "%d|password-assignment pattern\n", next_line
                            password_hit = 1
                        }
                    }
                    # Long opaque values beside a credential keyword. A line
                    # already reported as a password assignment is not also
                    # reported as entropy — one leak, one diagnostic.
                    entropy_pat = "(api[_-]?key|secret|token|password)[[:space:]]*[:=][[:space:]]*[\\042" q "\\042]?[-A-Za-z0-9_/+=.]+"
                    if (!password_hit && match(content, entropy_pat)) {
                        entropy_val = substr(content, RSTART, RLENGTH)
                        sub(/^[^:=]*[:=][[:space:]\042\047]*/, "", entropy_val)
                        if (length(entropy_val) >= 20 && entropy_val !~ /^[<\[]/) {
                            printf "%d|high-entropy secret-assignment pattern\n", next_line
                        }
                    }
                    if (!skip_narrative) {
                        for (rule_index = 1; rule_index <= rule_count; rule_index++) {
                            if (match(content, rule_regex[rule_index])) {
                                printf "%d|NARRATIVE|%s|%s\n", next_line, rule_name[rule_index], rule_severity[rule_index]
                            }
                        }
                    }
                    next_line++
                }
AWK
    ); then
        printf '%s\n' 'Staged secret scan failed while checking additions; stop before committing.' >&2
        exit 2
    fi

    escaped_path=$(escape_redacted_path "$path")
    while IFS='|' read -r line_number category detail severity; do
        [[ -n "$line_number" ]] || continue
        if [[ "$category" == NARRATIVE ]]; then
            printf "Narrative surface %s (%s) in staged additions: %s:%s (relativize the path to a \$HOME-relative form, or untrack the file).\\n" \
                "$detail" "$severity" "$escaped_path" "$line_number"
            narrative_found=1
        else
            printf 'Potential %s in staged additions: %s:%s (matching content suppressed).\n' \
                "$category" "$escaped_path" "$line_number"
            scan_found=1
        fi
    done <<< "$detections"
done <"$paths_file"

# Two-tier exit: secret findings keep precedence at 1, narrative findings use the
# dedicated 3 tier, and diagnostics for both are printed above before either exit.
if ((scan_found)); then
    exit 1
fi
if ((narrative_found)); then
    exit 3
fi
