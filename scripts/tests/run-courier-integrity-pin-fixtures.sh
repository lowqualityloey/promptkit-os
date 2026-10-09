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
const args = courier.installerArgs(['--balanced', '/tmp/project'], '9.8.7');
if (args.length !== 3 || args[2] !== '--engine-version=v9.8.7') process.exit(1);
NODE
echo 'PASS|pinned digest exported and courier version forwarded'

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

PLUS_TARGET="$TEMP_ROOT/plus-package/bin/promptkit-os.js"
mkdir -p "$(dirname "$PLUS_TARGET")"
cp "$SOURCE" "$PLUS_TARGET"
cp "$REPO_ROOT/package/package.json" "$TEMP_ROOT/plus-package/package.json"
"$HELPER" "$PLUS_TARGET" '9.8.7+build.6' "$PASS_DIGEST"
node - "$PLUS_TARGET" "$PASS_DIGEST" <<'NODE'
const courier = require(process.argv[2]);
if (courier.TARBALL_SHA256_BY_VERSION['9.8.7+build.6'] !== process.argv[3]) process.exit(1);
NODE
echo 'PASS|SemVer build metadata pin accepted'

NO_MARKER="$TEMP_ROOT/no-marker.js"
sed '/@pin-insert/d' "$SOURCE" > "$NO_MARKER"
if output="$("$HELPER" "$NO_MARKER" 9.8.7 "$PASS_DIGEST" 2>&1)"; then
    echo 'FAIL|missing marker was accepted' >&2
    exit 1
fi
[[ "$output" == *'integrity pin insertion marker missing or duplicated'* ]]
echo 'PASS|missing marker rejected with a clear error'

for tag in v1.2.3 v2.0.0-rc.1 v3.4.5+build.6; do
    [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]
done
invalid_tag=v1.2-unsafe
if [[ "$invalid_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
    echo 'FAIL|malformed tag accepted' >&2
    exit 1
fi
echo 'PASS|marker-compatible release tags validated'

grep -Fq 'default: true' "$WORKFLOW"
grep -Fq "if: github.event_name == 'release' || (inputs.dry_run == false && github.ref == 'refs/heads/main')" "$WORKFLOW"
grep -Fq "if: github.event_name == 'workflow_dispatch' && inputs.dry_run == true" "$WORKFLOW"
grep -Fq "archive/refs/tags/\$TAG.tar.gz" "$WORKFLOW"
grep -Fq 'Confirm Release Tag Still Targets Checked-Out Commit' "$WORKFLOW"
grep -Fq 'Reject Manual Publish Outside Main' "$WORKFLOW"
grep -Fq '(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?' "$WORKFLOW"
build_metadata_tag=v3.4.5+build.6
if [[ "$build_metadata_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    echo 'FAIL|workflow release-tag validation rejects SemVer build metadata' >&2
    exit 1
fi
echo 'PASS|manual dry run skips publish and release tags are checked'


echo '== executable courier policy (disposable archive and stub installers) =='
# The Node block is self-contained so it can also run under native Windows Node.
node - "$SOURCE" <<'NODE_FIXTURE'
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const source = fs.readFileSync(process.argv[2], 'utf8');
const version = '9.8.7';
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'promptkit-courier-exec-'));
try {
  const fixture = path.join(work, 'fixture', 'promptkit-os-v9.8.7');
  fs.mkdirSync(fixture, { recursive: true });
  fs.writeFileSync(path.join(fixture, 'init.sh'), '#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "$PROMPTKIT_STUB_MARKER"\n');
  fs.writeFileSync(path.join(fixture, 'init.ps1'), '$args | Set-Content -LiteralPath $env:PROMPTKIT_STUB_MARKER\n');
  const archive = path.join(work, 'fixture.tar.gz');
  const packed = spawnSync('tar', ['-czf', archive, '-C', path.join(work, 'fixture'), 'promptkit-os-v9.8.7'], { stdio: 'inherit' });
  assert.equal(packed.status, 0, `stub archive creation: ${packed.error || packed.status}`);
  const digest = crypto.createHash('sha256').update(fs.readFileSync(archive)).digest('hex');
  const marker = '  // @pin-insert';
  assert.equal(source.split(marker).length, 2, 'exactly one pin insertion point');
  const pin = (value) => source.replace(marker, `  "${version}": "${value}",\n${marker}`);
  const packageRoot = path.join(work, 'couriers');
  const createCourier = (name, code) => {
    const dir = path.join(packageRoot, name);
    fs.mkdirSync(path.join(dir, 'bin'), { recursive: true });
    fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify({ name: 'promptkit-os', version }));
    const bin = path.join(dir, 'bin', 'promptkit-os.js');
    fs.writeFileSync(bin, code);
    return bin;
  };
  const good = createCourier('good', pin(digest));
  const missing = createCourier('missing', source);
  const badPin = createCourier('bad-pin', pin(`${digest}junk`));
  const wrongPin = createCourier('wrong-pin', pin('0'.repeat(64)));
  const preload = path.join(work, 'stub-fetch.js');
  fs.writeFileSync(preload, `const fs=require('node:fs');\nglobalThis.fetch=async url=>{fs.writeFileSync(process.env.PROMPTKIT_STUB_FETCH_MARKER,String(url));return {ok:true,arrayBuffer:async()=>fs.readFileSync(process.env.PROMPTKIT_STUB_ARCHIVE)};};\n`);
  let cases = 0;
  function run(name, bin, opts = {}) {
    const root = path.join(work, 'projects', name);
    fs.mkdirSync(root, { recursive: true });
    fs.writeFileSync(path.join(root, 'keep.txt'), 'untouched');
    if (opts.overlay) {
      fs.mkdirSync(path.join(root, '.promptkit'));
      fs.writeFileSync(path.join(root, '.promptkit', 'existing.txt'), 'untouched');
    }
    const fetchMarker = path.join(work, `${name}-fetch.txt`);
    const installerMarker = path.join(work, `${name}-installer.txt`);
    const stdout = path.join(work, `${name}-stdout.txt`);
    const stderr = path.join(work, `${name}-stderr.txt`);
    const env = { ...process.env, NODE_OPTIONS: `--require=${JSON.stringify(preload)}`,
      PROMPTKIT_STUB_ARCHIVE: archive, PROMPTKIT_STUB_FETCH_MARKER: fetchMarker,
      PROMPTKIT_STUB_MARKER: installerMarker };
    delete env.PROMPTKIT_TARBALL_SHA256;
    delete env.PROMPTKIT_REQUIRE_INTEGRITY_PIN;
    if (opts.override !== undefined) env.PROMPTKIT_TARBALL_SHA256 = opts.override;
    if (opts.strict) env.PROMPTKIT_REQUIRE_INTEGRITY_PIN = '1';
    const args = opts.args || ['--balanced', '--host=cursor', '--target=cursor', '--tracking=off', '--reconfigure'];
    const outFd = fs.openSync(stdout, 'w');
    const errFd = fs.openSync(stderr, 'w');
    let result;
    try {
      result = spawnSync(process.execPath, [bin, ...args, root],
        { cwd: root, env, stdio: ['ignore', outFd, errFd] });
    } finally {
      fs.closeSync(outFd); fs.closeSync(errFd);
    }
    if (result.error) throw result.error;
    const diagnostic = fs.readFileSync(stderr, 'utf8');
    const fetched = fs.existsSync(fetchMarker);
    const installed = fs.existsSync(installerMarker);
    const kitDir = path.join(root, '.promptkit');
    assert.equal(result.status, opts.exit ?? 0, `${name}: ${diagnostic}`);
    assert.equal(fetched, opts.fetch ?? true, `${name}: fetch`);
    assert.equal(installed, opts.install ?? true, `${name}: stub installer`);
    assert.equal(fs.existsSync(kitDir), opts.kit ?? true, `${name}: target mutation`);
    assert.equal(fs.readFileSync(path.join(root, 'keep.txt'), 'utf8'), 'untouched');
    if (opts.overlay) assert.equal(fs.readFileSync(path.join(kitDir, 'existing.txt'), 'utf8'), 'untouched');
    if (opts.message) assert.match(diagnostic, opts.message, `${name}: diagnostic`);
    if (fetched) assert.match(fs.readFileSync(fetchMarker, 'utf8'), /archive\/refs\/tags\/v9\.8\.7\.tar\.gz$/);
    if (installed) {
      assert.ok(fs.existsSync(path.join(kitDir, 'init.sh')), `${name}: archive extracted`);
      const forwarded = fs.readFileSync(installerMarker, 'utf8').trim().split(/\r?\n/);
      assert.deepEqual(forwarded, [...args.filter(arg => arg !== '--force'), root, `--engine-version=v${version}`], `${name}: installer arguments`);
    } else if (!opts.overlay) {
      assert.deepEqual(fs.readdirSync(root), ['keep.txt'], `${name}: no project mutation`);
    }
    console.log(`PASS|${name}: exit=${result.status}, fetch=${fetched}, target=${fs.existsSync(kitDir)}, installer=${installed}`);
    cases++;
  }
  run('own-version-pin', good, { message: /verified release tarball integrity/ });
  run('missing-own-version-pin', missing, { exit: 1, fetch: false, install: false, kit: false, message: /no integrity pin/ });
  run('missing-pin-strict', missing, { strict: true, exit: 1, fetch: false, install: false, kit: false, message: /no integrity pin/ });
  run('trusted-override', missing, { override: digest.toUpperCase(), message: /verified release tarball integrity/ });
  run('incorrect-override', good, { override: '0'.repeat(64), exit: 1, install: false, kit: false, message: /tarball integrity mismatch/ });
  run('malformed-embedded-pin', badPin, { exit: 1, fetch: false, install: false, kit: false, message: /invalid SHA-256 digest/ });
  for (const [index, invalid] of [digest.slice(0, 63), `${digest}x`, 'g'.repeat(64), '', ` ${digest}`].entries()) {
    run(`malformed-override-${index}`, good, { override: invalid, exit: 1, fetch: false, install: false, kit: false, message: /invalid SHA-256 digest/ });
  }
  run('wrong-embedded-pin', wrongPin, { exit: 1, install: false, kit: false, message: /tarball integrity mismatch/ });
  run('nonempty-target-guard', good, { overlay: true, exit: 1, fetch: false, install: false, message: /Refusing to overlay/ });
  run('explicit-force-and-profile', good, { overlay: true, args: ['--force', '--turbo', '--experimental', '--host=claude', '--tracking=on'], message: /verified release tarball integrity/ });
  console.log(`PASS|${cases} executable courier policy fixtures (stub archive, no real installer)`);
} finally {
  if (!work.startsWith(path.resolve(os.tmpdir()) + path.sep)) throw new Error('refusing to remove unexpected fixture path');
  fs.rmSync(work, { recursive: true, force: true });
}
NODE_FIXTURE
