#!/usr/bin/env bash
set -euo pipefail
repo=$(builtin cd -- "$(dirname -- "$0")/../.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir "$tmp/project with spaces"
root="$tmp/project with spaces"
scanner="$repo/scripts/check-harness-security.sh"
run_scan() {
    status=0
    output=$(bash "$scanner" "$root") || status=$?
    [[ "$status" -eq "$1" ]] || { printf 'FAIL: expected %s got %s\n' "$1" "$status"; exit 1; }
}
run_scan 0
[[ "$output" == *'FIXED_SCOPE_ONLY'* ]]
printf '%s\n' 'API_KEY=replace_me' > "$root/.env.example"
run_scan 0
secret="AKIA$(printf '%016d' 0)"
printf '%s\n' "$secret" > "$root/.env"
before=$(cksum < "$root/.env")
run_scan 1
[[ "$output" == *'SUSPECTED_SECRET|.env'* && "$output" != *"$secret"* ]]
[[ "$(cksum < "$root/.env")" == "$before" ]]
rm "$root/.env"
ln -s "$root/.env.example" "$root/.env"
run_scan 2
[[ "$output" == *'SYMLINK|.env'* ]]
rm "$root/.env"
mkfifo "$root/.env"
run_scan 2
[[ "$output" == *'UNREADABLE_OR_SPECIAL|.env'* ]]
rm "$root/.env"
dd if=/dev/zero of="$root/.env" bs=65537 count=1 2>/dev/null
run_scan 2
[[ "$output" == *'SIZE_LIMIT|.env'* ]]
rm "$root/.env"
printf '%s\n' '{"autoApprove":true}' > "$root/.mcp.json"
run_scan 1
[[ "$output" == *'BROAD_APPROVAL|.mcp.json'* ]]
rm "$root/.mcp.json"
output=$(PROMPTKIT_NO_INTERACTIVE=1 bash "$repo/init.sh" "$root")
[[ "$output" == *'PREFLIGHT|SCOPE|'* && -f "$root/PROMPTKIT.md" ]]
output=$(PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 bash "$repo/init.sh" "$root")
[[ "$output" == *'PREFLIGHT|SKIPPED|USER_OPT_OUT'* && "$output" != *'PREFLIGHT|SCOPE|'* ]]
git -C "$root" init -q
printf 'API_KEY=replace_me\n' > "$root/.env"
git -C "$root" add -- .env
printf '.env\n' > "$root/.gitignore"
index_before=$(cksum < "$root/.git/index")
run_scan 1
[[ "$output" == *'TRACKED_SENSITIVE|.env'* && "$output" != *'IGNORE_GAP|.env'* ]]
[[ "$(cksum < "$root/.git/index")" == "$index_before" ]]
printf '' > "$root/.gitignore"
run_scan 1
[[ "$output" == *'IGNORE_GAP|.env'* ]]
git -C "$root" rm --cached -q -- .env
printf '.env\n' > "$root/.gitignore"
run_scan 0
rm "$root/.env"
printf '' > "$root/.gitignore"
mkdir "$root/.claude"
printf '%s\n' '{"permissions":{"defaultMode":"bypassPermissions","allow":["Bash(*)"]}}' > "$root/.claude/settings.json"
run_scan 1
[[ "$output" == *'PERMISSION_BYPASS|.claude/settings.json'* && "$output" == *'BROAD_PERMISSION|.claude/settings.json'* ]]
rm "$root/.claude/settings.json"
printf '%s\n' '{"autoApprove":' 'true}' > "$root/.mcp.json"
run_scan 1
[[ "$output" == *'BROAD_APPROVAL|.mcp.json'* ]]
rm "$root/.mcp.json"
printf '\000' > "$root/.env.example"
run_scan 2
[[ "$output" == *'UNSUPPORTED_ENCODING|.env.example'* ]]
printf 'API_KEY=replace_me\n' > "$root/.env.example"
chmod 000 "$root/.env.example"
if [[ ! -r "$root/.env.example" ]]; then
    run_scan 2
    [[ "$output" == *'UNREADABLE_OR_SPECIAL|.env.example'* ]]
else
    printf '%s\n' 'SKIP: unreadable-file check requires non-root permissions.'
fi
chmod 600 "$root/.env.example"
printf '%s\n' 'Harness security regression tests passed.'
