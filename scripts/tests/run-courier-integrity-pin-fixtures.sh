#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPER="$REPO_ROOT/scripts/mint-courier-integrity-pin.sh"
SOURCE="$REPO_ROOT/package/bin/promptkit-os.js"
WORKFLOW="$REPO_ROOT/.github/workflows/release-npm.yml"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/promptkit-pin.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT

PASS_DIGEST=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
OTHER_DIGEST=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
TARGET="$TEMP_ROOT/package/bin/promptkit-os.js"
mkdir -p "$(dirname "$TARGET")"
cp "$SOURCE" "$TARGET"
printf '{"version":"9.8.7"}\n' > "$TEMP_ROOT/package/package.json"
node -e "const fs=require('node:fs');const p=process.argv[1];let s=fs.readFileSync(p,'utf8');s=s.replace(/^.*\"9\\.8\\.7\":.*\\n/m,'');fs.writeFileSync(p,s)" "$TARGET"

"$HELPER" "$TARGET" 9.8.7 "$PASS_DIGEST"
node - "$TARGET" "$PASS_DIGEST" <<'NODE'
const courier = require(process.argv[2]);
if (courier.TARBALL_SHA256_BY_VERSION['9.8.7'] !== process.argv[3]) process.exit(1);
NODE
echo 'PASS|missing pin inserted and exported'

before="$(sha256sum "$TARGET" | cut -d' ' -f1)"
"$HELPER" "$TARGET" 9.8.7 "$PASS_DIGEST"
after="$(sha256sum "$TARGET" | cut -d' ' -f1)"
[ "$before" = "$after" ]
echo 'PASS|matching pin unchanged'

if "$HELPER" "$TARGET" 9.8.7 "$OTHER_DIGEST" >/dev/null 2>&1; then
    echo 'FAIL|mismatched pin was accepted' >&2
    exit 1
fi
echo 'PASS|mismatched pin rejected'

NO_MARKER="$TEMP_ROOT/no-marker.js"
sed '/@pin-insert/d' "$SOURCE" > "$NO_MARKER"
if output="$("$HELPER" "$NO_MARKER" 9.8.7 "$PASS_DIGEST" 2>&1)"; then
    echo 'FAIL|missing marker was accepted' >&2
    exit 1
fi
[[ "$output" == *'integrity pin insertion marker missing or duplicated'* ]]
echo 'PASS|missing marker rejected with a clear error'

for tag in v1.2.3 v2.0.0-rc.1 v3.4.5+build.6; do
    [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]
done
if [[ v1.2-unsafe =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo 'FAIL|malformed tag accepted' >&2
    exit 1
fi
echo 'PASS|marker-compatible release tags validated'

grep -Fq 'default: true' "$WORKFLOW"
grep -Fq "if: github.event_name == 'release' || inputs.dry_run == false" "$WORKFLOW"
grep -Fq "if: github.event_name == 'workflow_dispatch' && inputs.dry_run == true" "$WORKFLOW"
echo 'PASS|manual dry run skips the publish step'
