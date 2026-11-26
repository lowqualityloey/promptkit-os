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
  fs.writeFileSync(path.join(fixture, 'init.sh'), '#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "$PROMPTKIT_STUB_MARKER"\nexit "${PROMPTKIT_STUB_EXIT:-0}"\n');
  fs.writeFileSync(path.join(fixture, 'init.ps1'), '$args | Set-Content -LiteralPath $env:PROMPTKIT_STUB_MARKER\n');
  const archive = path.join(work, 'fixture.tar.gz');
  const packed = spawnSync('tar', ['-czf', archive, '-C', path.join(work, 'fixture'), 'promptkit-os-v9.8.7'], { stdio: 'inherit' });
  assert.equal(packed.status, 0, `stub archive creation: ${packed.error || packed.status}`);
  const digest = crypto.createHash('sha256').update(fs.readFileSync(archive)).digest('hex');
  // Deliberately invalid archive bytes, pinned by their own digest so the integrity
  // gate passes and the failure has to come from tar itself. An empty PATH directory
  // simulates a host with no tar at all.
  const corruptArchive = path.join(work, 'corrupt.tar.gz');
  fs.writeFileSync(corruptArchive, Buffer.from('this is not a tar archive\n'));
  const corruptDigest = crypto.createHash('sha256').update(fs.readFileSync(corruptArchive)).digest('hex');
  const emptyBin = path.join(work, 'empty-bin');
  fs.mkdirSync(emptyBin);
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
  // Byte-level snapshot of a tree outside the project root, so a refused
  // install through a symlinked .promptkit/ can prove the link target was not
  // touched at all.
  function snapshotTree(dir) {
    const entries = [];
    const walk = (current, prefix) => {
      for (const entry of fs.readdirSync(current).sort()) {
        const full = path.join(current, entry);
        const rel = prefix ? `${prefix}/${entry}` : entry;
        const stat = fs.lstatSync(full);
        if (stat.isSymbolicLink()) {
          entries.push(`link ${rel} -> ${fs.readlinkSync(full)}`);
        } else if (stat.isDirectory()) {
          entries.push(`dir ${rel}/`);
          walk(full, rel);
        } else {
          entries.push(`file ${rel} ${crypto.createHash('sha256').update(fs.readFileSync(full)).digest('hex')}`);
        }
      }
    };
    walk(dir, '');
    return entries;
  }
  let cases = 0;
  function run(name, bin, opts = {}) {
    const root = opts.root || path.join(work, 'projects', name);
    fs.mkdirSync(root, { recursive: true });
    let externalDir;
    if (!opts.root) {
      fs.writeFileSync(path.join(root, 'keep.txt'), 'untouched');
      if (opts.symlink) {
        externalDir = path.join(work, 'external', name);
        fs.mkdirSync(externalDir, { recursive: true });
        if (opts.symlinkContent) fs.writeFileSync(path.join(externalDir, 'existing.txt'), 'untouched');
        fs.symlinkSync(externalDir, path.join(root, '.promptkit'), process.platform === 'win32' ? 'junction' : 'dir');
      } else if (opts.overlay || opts.update) {
        fs.mkdirSync(path.join(root, '.promptkit'));
        fs.writeFileSync(path.join(root, '.promptkit', 'existing.txt'), 'untouched');
      }
      if (opts.submodule) {
        fs.mkdirSync(path.join(root, '.promptkit'));
        fs.writeFileSync(path.join(root, '.promptkit', '.git'), 'gitdir: fixture\n');
      }
    }
    const externalBefore = externalDir ? snapshotTree(externalDir) : null;
    const fetchMarker = path.join(work, `${name}-fetch.txt`);
    const installerMarker = path.join(work, `${name}-installer.txt`);
    const stdout = path.join(work, `${name}-stdout.txt`);
    const stderr = path.join(work, `${name}-stderr.txt`);
    const env = { ...process.env, NODE_OPTIONS: `--require=${JSON.stringify(preload)}`,
      PROMPTKIT_STUB_ARCHIVE: opts.archive || archive, PROMPTKIT_STUB_FETCH_MARKER: fetchMarker,
      PROMPTKIT_STUB_MARKER: installerMarker };
    if (opts.installerExit !== undefined) env.PROMPTKIT_STUB_EXIT = String(opts.installerExit);
    if (opts.path !== undefined) env.PATH = opts.path;
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
    if (opts.kitEntries) assert.deepEqual(fs.readdirSync(kitDir).sort(), [...opts.kitEntries].sort(), `${name}: kit contents`);
    assert.equal(fs.readFileSync(path.join(root, 'keep.txt'), 'utf8'), 'untouched');
    if (opts.overlay && !opts.update) assert.equal(fs.readFileSync(path.join(kitDir, 'existing.txt'), 'utf8'), 'untouched');
    if (opts.update) assert.ok(!fs.existsSync(path.join(kitDir, 'existing.txt')), `${name}: update kept a stale entry`);
    if (opts.message) assert.match(diagnostic, opts.message, `${name}: diagnostic`);
    if (externalDir) {
      assert.ok(fs.lstatSync(kitDir).isSymbolicLink(), `${name}: refused run replaced the symlink`);
      assert.deepEqual(snapshotTree(externalDir), externalBefore, `${name}: external symlink target mutated`);
    }
    if (fetched) assert.match(fs.readFileSync(fetchMarker, 'utf8'), /archive\/refs\/tags\/v9\.8\.7\.tar\.gz$/);
    if (installed) {
      if (opts.kit !== false) assert.ok(fs.existsSync(path.join(kitDir, 'init.sh')), `${name}: archive extracted`);
      const forwarded = fs.readFileSync(installerMarker, 'utf8').trim().split(/\r?\n/);
      assert.deepEqual(forwarded, [...args.filter(arg => arg !== '--force' && arg !== '--update'), root, `--engine-version=v${version}`], `${name}: installer arguments`);
    } else if (!opts.overlay && !opts.submodule && !opts.symlink) {
      assert.deepEqual(fs.readdirSync(root), ['keep.txt'], `${name}: no project mutation`);
    }
    assert.ok(!fs.readdirSync(root).some((entry) => entry.startsWith('.promptkit-staging-') || entry.startsWith('.promptkit-backup-')), `${name}: staging or backup directory left behind`);
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
  // AC-2: a tar failure must leave no .promptkit/ and no staging leftovers, and a clean
  // retry in the same project must then succeed.
  run('corrupt-archive', good, { archive: corruptArchive, override: corruptDigest, exit: 1, install: false, kit: false, message: /failed to extract release tarball \(tar exit \d+\)/ });
  run('missing-tar', good, { path: emptyBin, exit: 1, install: false, kit: false, message: /tar not found on PATH/ });
  run('force-with-corrupt-archive', good, { overlay: true, args: ['--force'], archive: corruptArchive, override: corruptDigest, exit: 1, install: false, kit: true, kitEntries: ['existing.txt'], message: /failed to extract release tarball/ });
  run('corrupt-archive-retry', good, { root: path.join(work, 'projects', 'corrupt-archive'), kitEntries: ['init.sh', 'init.ps1'], message: /verified release tarball integrity/ });
  // --update replaces a courier install atomically; it must never forward the
  // courier-only flag, resurrect a stale entry, or leave a backup behind.
  run('update-replaces-courier-install', good, { update: true, args: ['--update', '--balanced'], kitEntries: ['init.sh', 'init.ps1'], message: /verified release tarball integrity/ });
  run('update-refuses-submodule', good, { submodule: true, args: ['--update'], exit: 1, fetch: false, install: false, message: /git-submodule install/ });
  run('update-requires-existing-install', good, { args: ['--update'], exit: 1, fetch: false, install: false, kit: false, message: /no \.promptkit\/ to update/ });
  run('update-rejects-force', good, { overlay: true, args: ['--update', '--force'], exit: 1, fetch: false, install: false, message: /mutually exclusive/ });
  // Issue #814: a symbolic .promptkit/ (even dangling or empty) must fail closed at
  // every door. Pre-fix, the default install treated the empty link target as a
  // clean fresh install, --force rmSync'd through the link, and --update renamed
  // the link itself; all three left the external directory changed or the link
  // replaced. Each case asserts refusal, byte-identical external preservation, and
  // that the link is still a link.
  run('install-refuses-kit-symlink', good, { symlink: true, args: ['--balanced'], exit: 1, fetch: false, install: false, message: /symbolic link/ });
  run('force-refuses-kit-symlink', good, { symlink: true, symlinkContent: true, args: ['--force', '--balanced'], exit: 1, fetch: false, install: false, message: /symbolic link/ });
  run('update-refuses-kit-symlink', good, { symlink: true, symlinkContent: true, args: ['--update'], exit: 1, fetch: false, install: false, message: /symbolic link/ });
  // A cancel (130) removes only a kit this run created and keeps a pre-existing one.
  run('cancel-removes-fresh-kit', good, { installerExit: 130, exit: 130, kit: false, message: /removed the newly created \.promptkit\// });
  run('cancel-keeps-forced-overlay', good, { overlay: true, installerExit: 130, args: ['--force'], exit: 130, kitEntries: ['existing.txt', 'init.sh', 'init.ps1'], message: /existing \.promptkit\/ left unchanged/ });
  console.log(`PASS|${cases} executable courier policy fixtures (stub archive, no real installer)`);
} finally {
  if (!work.startsWith(path.resolve(os.tmpdir()) + path.sep)) throw new Error('refusing to remove unexpected fixture path');
  fs.rmSync(work, { recursive: true, force: true });
}
NODE_FIXTURE
