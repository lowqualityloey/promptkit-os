#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/promptkit-release-archive.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT
FIXTURE="$TEMP_ROOT/repo"
mkdir -p "$FIXTURE"
git -C "$FIXTURE" init -q
git -C "$FIXTURE" -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty -qm baseline
printf 'release source\n' > "$FIXTURE/source.txt"
chmod 755 "$FIXTURE/source.txt"
git -C "$FIXTURE" add source.txt
git -C "$FIXTURE" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm source
COMMIT="$(git -C "$FIXTURE" rev-parse HEAD)"
git -C "$FIXTURE" archive --format=tar --prefix=fixture-tag/ "$COMMIT" | gzip -n > "$TEMP_ROOT/matching.tar.gz"

python3 "$REPO_ROOT/scripts/verify-release-archive.py" --archive "$TEMP_ROOT/matching.tar.gz" --commit "$COMMIT" --repository "$FIXTURE"
printf 'PASS|matching commit archive\n'

printf 'tampered source\n' > "$FIXTURE/source.txt"
git -C "$FIXTURE" add source.txt
git -C "$FIXTURE" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm tampered
git -C "$FIXTURE" archive --format=tar --prefix=fixture-tag/ HEAD | gzip -n > "$TEMP_ROOT/tampered.tar.gz"
if python3 "$REPO_ROOT/scripts/verify-release-archive.py" --archive "$TEMP_ROOT/tampered.tar.gz" --commit "$COMMIT" --repository "$FIXTURE"; then
    echo 'FAIL|tampered archive was accepted' >&2
    exit 1
fi
printf 'PASS|archive from different commit rejected\n'
