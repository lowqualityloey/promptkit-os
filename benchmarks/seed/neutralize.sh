#!/usr/bin/env bash
# Neutralize a seed repository for the Phase 3b A/B benchmark.
#
#   neutralize.sh <source-repo> <dest-dir>
#
# Phase 3b (benchmarks/PHASE-3B-PROTOCOL.md section 3.1) requires both arms to
# start from the same neutral clone. A tracked AGENTS.md, CLAUDE.md, PROMPTKIT.md,
# GEMINI.md, .cursorrules, .windsurfrules, .clinerules, .cursor/rules/,
# .claude/, .promptkit/, .github/instructions/ or copilot-instructions.md would
# be inherited by BOTH arms, so it cannot stay; a tracked PROMPTKIT.md is worse
# than inherited text, because init.sh reads it as an existing install and keeps
# that profile instead of writing the Balanced directive.
#
# This script produces that clone deterministically, so the "neutralization
# procedure SHA" Appendix B records names a reproducible step rather than an
# operator's memory of what was deleted. The surface list is exactly the one
# benchmarks/run-ab-benchmark.sh's seed guard enforces: the guard stays the
# authority, and this script cannot drift into removing less than the guard
# refuses.
#
# Like benchmarks/run-ab-benchmark.sh this is operator-local Bash with no
# PowerShell twin: it drives git, not a CLI, so CI covers it with a syntax check
# plus the driver harness's end-to-end neutralization cases.
#
# Output (stdout, one machine line):
#   NEUTRALIZE|OK|source=<sha>|seed=<sha>|removed=<n>|script_sha256=<hash>
#   NEUTRALIZE|ALREADY|<sha>|dest=<path>
# Errors go to stderr as NEUTRALIZE|ERROR|<reason> and exit 2, failing closed.
#
# The script does not run the seed's test suite: only the operator knows its
# command and its dependency install. Section 3.1 requires the neutralized
# seed's tests to pass, and Appendix D requires every task Verify command to
# run against it, so run both after neutralization and record the result.

set -euo pipefail
export LC_ALL=C

SURFACE_RE='(^|/)(AGENTS\.md|CLAUDE\.md|PROMPTKIT\.md|GEMINI\.md|\.cursorrules|\.windsurfrules|\.clinerules|copilot-instructions\.md)$|(^|/)(\.cursor/rules|\.claude|\.promptkit|\.github/instructions)/'

die() {
    printf 'NEUTRALIZE|ERROR|%s\n' "$1" >&2
    exit 2
}

[[ $# -eq 2 ]] || die "usage: neutralize.sh <source-repo> <dest-dir>"
src=${1%/}
dest=${2%/}
[[ -n "$src" ]] || die "empty source path"
[[ -n "$dest" ]] || die "empty dest path"

command -v git >/dev/null 2>&1 || die "git is not on PATH"
git -C "$src" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "source is not a git work tree: $src"

# A dirty source cannot be pinned: the recorded seed SHA must describe exactly
# the tree the batch ran against.
[[ -z "$(git -C "$src" status --porcelain 2>/dev/null)" ]] \
    || die "source working tree is dirty, so a recorded seed SHA would not describe the batch: $src"

source_sha=$(git -C "$src" rev-parse HEAD) || die "cannot read source HEAD"
script_sha=$(sha256sum "$0" | awk '{print $1}')

tmp=$(mktemp -d "${TMPDIR:-/tmp}/neutralize.XXXXXX") || die "cannot create a temporary directory"
trap 'rm -rf -- "$tmp"' EXIT

# Clone rather than copy: a clone materializes tracked content only, so ignored
# build output, editor state, and untracked scratch files cannot leak into the
# seed either arm sees.
git -c core.autocrlf=false clone -q --no-local "$src" "$tmp/clone" \
    || die "clone failed for: $src"
clone="$tmp/clone"
[[ "$(git -C "$clone" rev-parse HEAD)" == "$source_sha" ]] \
    || die "clone HEAD does not match source HEAD"

removed=0
while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    git -C "$clone" rm -q -- "$path" || die "cannot remove tracked surface: $path"
    removed=$((removed + 1))
done < <(git -c core.quotepath=false -C "$clone" ls-files | grep -E -i -e "$SURFACE_RE" || true)

# heyloey cannot be scrubbed automatically: it appears in prose, hook names, and
# stored paths, and a blind rewrite could silently change what a task asks for.
# Refuse and name the files instead; the operator either neutralizes them by hand
# with the reason recorded, or chooses a seed that does not carry them.
leaks=$(git -C "$clone" grep -I -i -l -e heyloey -- . 2>/dev/null | head -5 || true)
if [[ -n "$leaks" ]]; then
    printf 'NEUTRALIZE|ERROR|heyloey reference survives neutralization; edit these files or choose another seed:\n%s\n' "$leaks" >&2
    exit 2
fi

if [[ -n "$(git -C "$clone" status --porcelain)" ]]; then
    # Fixed identity and timestamp: identical source content must produce an
    # identical seed SHA on any host, so Appendix B can pin it.
    GIT_AUTHOR_DATE='2000-01-01T00:00:00+0000' \
    GIT_COMMITTER_DATE='2000-01-01T00:00:00+0000' \
    git -c user.name='promptkit-bench' -c user.email='bench@invalid' \
        -c commit.gpgsign=false -c core.autocrlf=false \
        -C "$clone" commit -q --no-verify -m 'chore: neutralize seed for Phase 3b' \
        || die "neutralization commit failed"
fi

seed_sha=$(git -C "$clone" rev-parse HEAD) || die "cannot read neutralized HEAD"

# Idempotence without destruction: an existing dest is accepted only when it is
# already the same neutralized seed. A regular file, a symlink, and a directory
# that is not a clone are refused untouched, and an empty directory is cleared
# with rmdir rather than a recursive delete this script did not create.
if [[ -e "$dest" || -L "$dest" ]]; then
    [[ ! -L "$dest" && -d "$dest" ]] \
        || die "dest exists and is not a directory, so it was left untouched: $dest"
    if [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
        # Requiring $dest/.git is not redundant: without it a directory nested
        # inside another checkout resolves that repo's HEAD and reports ALREADY
        # for a path the driver would then reject as not a clone.
        if [[ -d "$dest/.git" ]]; then
            existing=$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)
            if [[ "$existing" == "$seed_sha" ]] \
                    && [[ -z "$(git -C "$dest" status --porcelain 2>/dev/null)" ]]; then
                printf 'NEUTRALIZE|ALREADY|%s|dest=%s\n' "$seed_sha" "$dest"
                exit 0
            fi
        fi
        die "dest exists and is not this neutralized seed, so it was left untouched: $dest"
    fi
    rmdir -- "$dest" || die "cannot clear the empty dest: $dest"
fi

mkdir -p -- "$(dirname -- "$dest")" 2>/dev/null || true
mv -- "$clone" "$dest" || die "cannot move the neutralized clone into: $dest"

printf 'NEUTRALIZE|OK|source=%s|seed=%s|removed=%s|script_sha256=%s\n' \
    "$source_sha" "$seed_sha" "$removed" "$script_sha"
