#!/usr/bin/env bash
# Read-only pk:doctor health detector for a PromptKit OS install (#547).
#
# Usage: scripts/check-doctor.sh [KIT_ROOT] [--fix]
#
# Reports host directive blocks, engine version/drift, managed-path ignore
# state, and docs state-store drift. Read-only by default: it never stages,
# commits, edits, or runs an upgrade. The only permitted write is `--fix`,
# which re-emits a MISSING managed directive block into an installed host file
# (the profile-appropriate template with $ENGINE_VERSION/$ENGINE_SHA substituted
# exactly as init.sh does). No other write ever happens.
#
# Machine-readable output: exactly one TAB-separated row per check, stable field
# order `<scope>\t<STATUS>\t<detail>\t<remediation>`. STATUS is the base token,
# optionally qualified in parentheses: OK | STALE(+n) | MISSING |
# IGNORED(<rule source>) | DIVERGED(<pair>) | SKIP(<reason>) | INCOMPLETE.
#
# Exit codes (contract):
#   0  every row is OK, IGNORED(...), or SKIP(...)
#   1  at least one STALE(...), MISSING, DIVERGED(...), or INCOMPLETE
#   2  doctor could not run at all (no PROMPTKIT.md at KIT_ROOT, or --fix
#      requested while no directive template exists)
# IGNORED never contributes to exit 1. INCOMPLETE is fail-closed and does
# (exit 1, never 0 and never 2). Precedence: 2 only when no check could run.

set -euo pipefail
export LC_ALL=C

script_dir="$(builtin cd -- "$(dirname -- "$0")" && pwd -P)" || exit 2
engine_root="$(builtin cd -- "$script_dir/.." && pwd -P)" || engine_root="$script_dir/.."

kit_root="."
fix=0

usage() {
    cat >&2 <<'EOF'
Usage: scripts/check-doctor.sh [KIT_ROOT] [--fix]
EOF
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --fix) fix=1; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) usage; exit 2 ;;
        *) kit_root="$1"; shift ;;
    esac
done

fail=0

# Rows are emitted as they are computed. `fail` tracks only statuses that make
# the overall verdict unhealthy; IGNORED and SKIP never set it.
emit() {
    local scope="$1" status="$2" detail="$3" remediation="$4"
    printf '%s\t%s\t%s\t%s\n' "$scope" "$(san "$status")" "$(san "$detail")" "$(san "$remediation")"
    local base="${status%%(*}"
    case "$base" in
        STALE|MISSING|DIVERGED|INCOMPLETE) fail=1 ;;
    esac
}

san() { printf '%s' "$1" | tr '\r\n\t' '   '; }

if [[ ! -d "$kit_root" ]]; then
    emit 'prereq' 'INCOMPLETE' 'no PROMPTKIT.md at KIT_ROOT' 'Run pk:doctor from the project root that contains PROMPTKIT.md'
    exit 2
fi
kit_root="$(builtin cd -- "$kit_root" && pwd -P)" || exit 2

# The kit root must carry PROMPTKIT.md; without it no check has a scope to run
# against, so this is the exit-2 "could not run at all" prerequisite.
if [[ ! -f "$kit_root/PROMPTKIT.md" || ! -r "$kit_root/PROMPTKIT.md" ]]; then
    emit 'prereq' 'INCOMPLETE' 'no PROMPTKIT.md at KIT_ROOT' 'Run pk:doctor from the project root that contains PROMPTKIT.md'
    exit 2
fi

# Declared profile: mirror the installer's exact parse (init.sh line ~456).
profile="$(grep -E '^profile:' "$kit_root/PROMPTKIT.md" 2>/dev/null | tail -n 1 | awk '{print $2}' || true)"
[[ -n "$profile" ]] || profile="balanced"

# Known host -> directive file map, verbatim from init.sh host_file().
host_relpath() {
    case "$1" in
        agents) printf 'AGENTS.md' ;;
        claude) printf 'CLAUDE.md' ;;
        opencode) printf '.opencode/rules.md' ;;
        cursor) printf '.cursorrules' ;;
        gemini) printf 'GEMINI.md' ;;
        windsurf) printf '.windsurfrules' ;;
        copilot) printf '.github/copilot-instructions.md' ;;
        cline) printf '.clinerules' ;;
        trae) printf '.traerules' ;;
        aider) printf 'CONVENTIONS.md' ;;
        *) printf '' ;;
    esac
}
HOST_IDS="agents claude opencode cursor gemini windsurf copilot cline trae aider"

# Exact marker regex from init.sh: `[[:space:]]*` also swallows a trailing CR,
# so CRLF host files match just like LF ones.
has_block() {
    grep -qE '^[[:space:]]*<!-- PROMPTKIT_START -->[[:space:]]*$' -- "$1" 2>/dev/null
}

sed_replacement_escape() {
    printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g' | tr '\n' ' '
}

# Engine stamp: first installed host directive carrying an `Engine: <ver> (<sha>)`
# line. This is the reporting authority for the version row.
stamp_ver=""
stamp_sha=""
for id in $HOST_IDS; do
    rel="$(host_relpath "$id")"
    path="$kit_root/$rel"
    [[ -f "$path" && -r "$path" ]] || continue
    stamp_line="$(grep -m1 -E '^[[:space:]]*Engine:' -- "$path" 2>/dev/null || true)"
    if [[ -n "$stamp_line" && "$stamp_line" =~ ^[[:space:]]*Engine:[[:space:]]*([^[:space:]]+)[[:space:]]*\(([^\)]*)\) ]]; then
        stamp_ver="${BASH_REMATCH[1]}"
        stamp_sha="${BASH_REMATCH[2]}"
        break
    fi
done

# STATE.md engine stamp (fallback identity source for --fix; never authoritative).
state_ver=""
state_sha=""
if [[ -f "$kit_root/docs/STATE.md" ]]; then
    state_line="$(grep -m1 -E '^- \*\*Engine Version\*\*:' -- "$kit_root/docs/STATE.md" 2>/dev/null || true)"
    if [[ -n "$state_line" && "$state_line" != *'['* && "$state_line" =~ ^-\ \*\*Engine\ Version\*\*:[[:space:]]*(.+)[[:space:]]@[[:space:]]*([^[:space:]]+) ]]; then
        state_ver="${BASH_REMATCH[1]}"
        state_sha="${BASH_REMATCH[2]}"
        state_ver="${state_ver%"${state_ver##*[![:space:]]}"}"
    fi
fi

# --fix template resolution, mirroring init.sh's lite-fallback behavior.
template=""
if [[ "$fix" -eq 1 ]]; then
    if [[ "$profile" == "lite" ]]; then
        template="$engine_root/templates/agent-directive-lite-template.md"
        [[ -f "$template" ]] || template="$engine_root/templates/agent-directive-template.md"
    else
        template="$engine_root/templates/agent-directive-template.md"
    fi
    if [[ ! -f "$template" ]]; then
        emit 'fix' 'INCOMPLETE' 'directive template unavailable' 'Restore templates/agent-directive-template.md from the kit'
        exit 2
    fi
fi

# Render the managed directive block exactly as init.sh does.
render_directive() {
    local kit_dir_rel ver sha
    kit_dir_rel="$(basename -- "$kit_root")"
    ver="$stamp_ver"
    [[ -n "$ver" ]] || ver="$state_ver"
    sha="$stamp_sha"
    [[ -n "$sha" ]] || sha="$state_sha"
    if [[ -z "$ver" || -z "$sha" ]]; then
        local d s
        d="$(git -C "$kit_root" describe --tags --match 'v[0-9]*' 2>/dev/null || true)"
        s="$(git -C "$kit_root" rev-parse --short HEAD 2>/dev/null || true)"
        [[ -n "$ver" ]] || ver="${d:-unknown}"
        [[ -n "$sha" ]] || sha="${s:-unknown}"
    fi
    local sed_kit sed_ver sed_sha
    sed_kit="$(sed_replacement_escape "$kit_dir_rel")"
    sed_ver="$(sed_replacement_escape "$ver")"
    sed_sha="$(sed_replacement_escape "$sha")"
    sed -e "s|\\\$KIT_DIR_REL|$sed_kit|g" \
        -e "s|\\\$ENGINE_VERSION|$sed_ver|g" \
        -e "s|\\\$ENGINE_SHA|$sed_sha|g" "$template"
}

fix_host_block() {
    local path="$1" rendered
    rendered="$(render_directive)" || return 1
    if [[ -s "$path" ]]; then
        printf '\n\n%s\n' "$rendered" >> "$path"
    else
        printf '%s\n' "$rendered" > "$path"
    fi
}

# --- Check 1: hosts -------------------------------------------------------
# Enumerate the installer's host_file() map. A file that INSTALLED (exists) is
# checked for the managed block; a file not present is SKIP(not installed) and
# is never flagged MISSING. Declared mode scopes expectations: a Lite install
# is not judged against Balanced-only workflow lists, so the only host-level
# expectation is the managed directive block itself, identical for both modes.
INSTALLED_HOSTS=()
for id in $HOST_IDS; do
    rel="$(host_relpath "$id")"
    [[ -n "$rel" ]] || continue
    path="$kit_root/$rel"
    if [[ ! -e "$path" ]]; then
        emit "host:$rel" 'SKIP(not installed)' 'host file not present' '-'
        continue
    fi
    if [[ ! -f "$path" || ! -r "$path" ]]; then
        emit "host:$rel" 'INCOMPLETE' 'host file unreadable' 'Restore read access to the host directive file'
        INSTALLED_HOSTS+=("$rel")
        continue
    fi
    if has_block "$path"; then
        emit "host:$rel" 'OK' 'managed directive block present' '-'
    elif [[ "$fix" -eq 1 ]]; then
        if fix_host_block "$path" && has_block "$path"; then
            emit "host:$rel" 'OK' 'managed directive block re-emitted by --fix' '-'
        else
            emit "host:$rel" 'MISSING' 'no PROMPTKIT_START block' 'Run the installer or pk:doctor --fix to re-emit the managed directive block'
        fi
    else
        emit "host:$rel" 'MISSING' 'no PROMPTKIT_START block' 'Run the installer or pk:doctor --fix to re-emit the managed directive block'
    fi
    INSTALLED_HOSTS+=("$rel")
done

# --- Check 2: version -----------------------------------------------------
# Issue #545's six-state table (workflows/sync.md, Engine Version & Drift
# Audit), implemented as read-only git comparisons. Map: ok->OK,
# behind(+n)->STALE(+n), diverged->DIVERGED, unknown->SKIP(no engine stamp),
# shallow-or-offline->SKIP(shallow-or-offline), not-a-git-install->
# SKIP(not-a-git-install). Tests run top-to-bottom, first match wins.
resolve_upstream() {
    local sym c
    sym="$(git -C "$kit_root" -c core.fsmonitor=false symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [[ -n "$sym" ]] && git -C "$kit_root" -c core.fsmonitor=false rev-parse --verify --quiet "$sym^{commit}" >/dev/null 2>&1; then
        printf '%s' "$sym"
        return 0
    fi
    for c in refs/remotes/origin/main refs/remotes/origin/master refs/remotes/upstream/main origin/main origin/master; do
        if git -C "$kit_root" -c core.fsmonitor=false rev-parse --verify --quiet "$c^{commit}" >/dev/null 2>&1; then
            printf '%s' "$c"
            return 0
        fi
    done
    return 0
}

check_version() {
    if [[ -z "$stamp_ver" || -z "$stamp_sha" ]]; then
        emit 'version' 'SKIP(no engine stamp)' 'no Engine: <ver> (<sha>) stamp in any installed host directive' 'Re-run the installer to stamp the engine identity'
        return 0
    fi
    if [[ ! -e "$kit_root/.git" ]]; then
        emit 'version' 'SKIP(not-a-git-install)' 'no .git in kit root (courier install)' 'Version comes from the release tarball; no git drift to measure'
        return 0
    fi
    if ! command -v git >/dev/null 2>&1; then
        emit 'version' 'SKIP(shallow-or-offline)' 'git unavailable' 'Install git to enable engine drift checks'
        return 0
    fi
    local is_shallow upstream mb count
    is_shallow="$(git -C "$kit_root" -c core.fsmonitor=false rev-parse --is-shallow-repository 2>/dev/null || true)"
    if [[ "$is_shallow" != "false" ]]; then
        emit 'version' 'SKIP(shallow-or-offline)' 'shallow or offline checkout' 'Fetch full history (git fetch --unshallow) to check drift'
        return 0
    fi
    upstream="$(resolve_upstream)"
    if [[ -z "$upstream" ]]; then
        emit 'version' 'SKIP(shallow-or-offline)' 'upstream ref unresolved' 'Resolve origin/main (or the engine default branch) to enable drift checks'
        return 0
    fi
    if git -C "$kit_root" -c core.fsmonitor=false merge-base --is-ancestor HEAD "$upstream" >/dev/null 2>&1; then
        mb=0
    else
        mb=$?
    fi
    if [[ "$mb" -eq 1 ]]; then
        emit 'version' "DIVERGED" "engine $stamp_ver diverged from $upstream" 'Reconcile the engine checkout with upstream manually; doctor never fetches or resets'
        return 0
    fi
    if [[ "$mb" -ne 0 ]]; then
        emit 'version' 'SKIP(shallow-or-offline)' "merge-base returned unexpected status $mb" 'Resolve the upstream ref and re-run'
        return 0
    fi
    count="$(git -C "$kit_root" -c core.fsmonitor=false rev-list --count "HEAD..$upstream" 2>/dev/null || true)"
    if [[ -z "$count" ]]; then
        emit 'version' 'SKIP(shallow-or-offline)' 'rev-list failed' 'Resolve the upstream ref and re-run'
        return 0
    fi
    if [[ "$count" -gt 0 ]]; then
        emit 'version' "STALE(+$count)" "engine $stamp_ver is $count commit(s) behind $upstream" 'Offer pk:sync upgrade (read-only doctor never upgrades)'
    else
        emit 'version' 'OK' "engine $stamp_ver ($stamp_sha) current" '-'
    fi
    return 0
}

check_version

# --- Check 3: ignore-state ------------------------------------------------
# Three-way status branch from check-harness-security.sh:58-72. `--no-index`
# matches that precedent: it classifies managed paths by the ignore rules that
# apply to them even when they are tracked, which is the question doctor asks.
# exit 0 -> IGNORED(<rule source>); exit 1 -> OK; anything else -> INCOMPLETE.
check_ignore_one() {
    local rel="$1" out st rule
    if out="$(git -C "$kit_root" -c core.fsmonitor=false check-ignore --no-index -v -- "$rel" 2>/dev/null)"; then
        st=0
    else
        st=$?
    fi
    case "$st" in
        0)
            rule="${out%%$'\t'*}"
            [[ -n "$rule" ]] || rule='(unknown rule)'
            emit "ignore:$rel" "IGNORED($rule)" 'managed path is matched by an ignore rule' 'Un-ignore the managed path if it must be tracked, or keep the intentional ignore'
            ;;
        1)
            emit "ignore:$rel" 'OK' 'not ignored' '-'
            ;;
        *)
            emit "ignore:$rel" 'INCOMPLETE' "git check-ignore returned unexpected status $st" 'Investigate why git could not classify the path'
            ;;
    esac
}

check_ignore_state() {
    if [[ ! -e "$kit_root/.git" ]]; then
        emit 'ignore:.' 'SKIP(not-a-git-install)' 'no .git in kit root (courier install)' 'Ignore state is not measurable without a git repository'
        emit 'ignore:PROMPTKIT.md' 'SKIP(not-a-git-install)' 'no .git in kit root (courier install)' '-'
        emit 'ignore:docs' 'SKIP(not-a-git-install)' 'no .git in kit root (courier install)' '-'
        return 0
    fi
    if ! command -v git >/dev/null 2>&1; then
        emit 'ignore:.' 'SKIP(git unavailable)' 'git unavailable' 'Install git to inspect ignore state'
        return 0
    fi
    check_ignore_one '.'
    check_ignore_one 'PROMPTKIT.md'
    check_ignore_one 'docs'
    # Explicit length guard: bash 3.2 errors on an empty array under `set -u`.
    if [[ "${#INSTALLED_HOSTS[@]}" -gt 0 ]]; then
        local hrel
        for hrel in "${INSTALLED_HOSTS[@]}"; do
            check_ignore_one "$hrel"
        done
    fi
    return 0
}

check_ignore_state

# --- Check 4: docs-drift --------------------------------------------------
# Three-store precedence (protocols/context-sync.md §3.2): the Task Record at
# docs/tasks/<task-id>.md is canonical, STATE.md §3A is a synchronized
# projection that must not override it, and a harness handoff store is
# reference-only and can NEVER introduce a DIVERGED verdict. The comparison is
# deliberately conservative: only fields present in both stores with
# unambiguous, non-placeholder values are compared. Any absent store degrades
# to SKIP(<reason>) and never fails the run.
proj_field() {
    local text="$1" label="$2" line val
    line="$(printf '%s\n' "$text" | grep -m1 -E "^- \*\*${label}\*\*:" 2>/dev/null || true)"
    if [[ -z "$line" ]]; then printf ''; return 0; fi
    val="${line#*:}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    val="${val#\`}"
    val="${val%\`}"
    val="${val%"${val##*[![:space:]]}"}"
    printf '%s' "$val"
}

is_placeholder() {
    local v="$1"
    if [[ -z "$v" || "$v" == '-' || "$v" == 'not tracked' ]]; then return 0; fi
    if [[ "$v" == *'<task-id>'* ]]; then return 0; fi
    if [[ "${v:0:1}" == '[' || "${v:0:1}" == '<' ]]; then return 0; fi
    return 1
}

check_docs_drift() {
    local state_file="$kit_root/docs/STATE.md"
    if [[ ! -f "$state_file" ]]; then
        emit 'docs-drift' 'SKIP(no STATE.md)' 'no docs/STATE.md' 'Create docs/STATE.md to enable the projection comparison'
        return 0
    fi
    local section
    section="$(awk '
        /^##[[:space:]]+3A\./ { f=1; next }
        f && /^##[[:space:]]/ { exit }
        f { print }
    ' "$state_file" 2>/dev/null || true)"
    if [[ -z "${section//[[:space:]]/}" ]]; then
        emit 'docs-drift' 'SKIP(no execution-control projection)' 'docs/STATE.md has no 3A section' 'Populate 3A when using Controlled Work'
        return 0
    fi
    local task_id task_record state_exec rec_rel rec_path rec_id rec_exec rec_text diff_field
    task_id="$(proj_field "$section" 'Task ID')"
    task_record="$(proj_field "$section" 'Task Record')"
    state_exec="$(proj_field "$section" 'Execution State')"
    if is_placeholder "$task_record" && is_placeholder "$task_id"; then
        emit 'docs-drift' 'SKIP(no task record)' 'no canonical Task Record referenced (no handoff.md and no Task Record)' 'Create docs/tasks/<task-id>.md for Controlled Work'
        return 0
    fi
    rec_rel="$task_record"
    if is_placeholder "$rec_rel" && ! is_placeholder "$task_id"; then
        rec_rel="docs/tasks/$task_id.md"
    fi
    if is_placeholder "$rec_rel" || [[ "$rec_rel" == /* || "$rec_rel" == *'..'* ]]; then
        emit 'docs-drift' 'SKIP(no task record)' 'canonical Task Record path is absent or unusable' 'Create docs/tasks/<task-id>.md for Controlled Work'
        return 0
    fi
    rec_path="$kit_root/$rec_rel"
    if [[ ! -f "$rec_path" || ! -r "$rec_path" ]]; then
        emit 'docs-drift' 'SKIP(no task record)' "canonical Task Record not found at $rec_rel" 'Create the referenced Task Record or fix its path'
        return 0
    fi
    rec_text="$(cat -- "$rec_path")"
    rec_id="$(proj_field "$rec_text" 'Task ID')"
    rec_exec="$(proj_field "$rec_text" 'Execution State')"
    diff_field=""
    if ! is_placeholder "$task_id" && ! is_placeholder "$rec_id" && [[ "$task_id" != "$rec_id" ]]; then
        diff_field='Task ID'
    elif ! is_placeholder "$state_exec" && ! is_placeholder "$rec_exec" && [[ "$state_exec" != "$rec_exec" ]]; then
        diff_field='Execution State'
    fi
    if [[ -n "$diff_field" ]]; then
        emit 'docs-drift' "DIVERGED(STATE 3A vs Task Record: $diff_field)" "projection disagrees with the canonical Task Record on $diff_field" 'Reconcile 3A to the Task Record (the Task Record is authoritative)'
    else
        emit 'docs-drift' 'OK' 'projection agrees with the canonical Task Record' '-'
    fi
    return 0
}

check_docs_drift

if [[ "$fail" -ne 0 ]]; then
    exit 1
fi
exit 0
