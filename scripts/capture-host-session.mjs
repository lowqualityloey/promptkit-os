#!/usr/bin/env node
// Capture harness for live host-conformance sessions.
//
// docs/internal/host-conformance/antigravity-capture-plan.md section 3.1 asks
// for a script that seeds a fixture, installs the kit with --host=gemini passed
// explicitly, applies the chosen isolation mechanism, drives agy over
// --input-format stream-json, and preserves the raw NDJSON stream. This is that
// script. It is the single implementation; capture-host-session.sh and
// capture-host-session.ps1 are thin forwarders, the same shape the transcript
// renderer uses.
//
// What it does, in order:
//
//   1. Reads the prompt and the directive profile out of the scenario file, so
//      the harness cannot drift from the scenario it is capturing.
//   2. Seeds a fresh git repository from the probe fixture and commits it. That
//      commit is the bundle's seedCommit.
//   3. Stages the kit at .promptkit/ from this checkout's HEAD (git archive, so
//      untracked scratch is never copied) and runs .promptkit/init.sh with
//      --host=gemini passed explicitly. The kit is excluded from the fixture's
//      git index on purpose: it is reproducible from promptkitCommit, and
//      committing 2,459 kit files would bury the install diff.
//   4. Runs the isolation canary twice - once unisolated, once under bwrap - and
//      records both results verbatim. The canary passes only when the read
//      FAILS, so an unisolated arm that succeeds is the proof the canary is
//      sensitive rather than vacuous.
//   5. Drives agy over stream-json inside bwrap and preserves stdout verbatim as
//      session.jsonl.
//   6. Derives session.relative.jsonl by rewriting the capture root out of tool
//      targets, renders transcript.md from it, and scores the bundle.
//
// The derivation in step 6 is disclosed rather than hidden. agy reports absolute
// paths, and the scorer's repo-unwritten check cannot resolve an absolute write
// target - it reports unjudgeable instead of passing, which would silently
// degrade a real violation to UNTESTED. Rewriting the capture root to a relative
// path is a deterministic spelling change, the raw stream is preserved beside
// it, and the transcript preamble names the stream it came from.

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const USAGE = [
  'Usage: capture-host-session <scenario> <bundle-dir> [options]',
  '',
  '  <scenario>    scenario name under scripts/tests/eval-scenarios/ (e.g. ce-sufficiency-balanced)',
  '  <bundle-dir>  directory to write the capture bundle into (created if absent)',
  '',
  'Options:',
  '  --model <id>      agy model id (default: gemini-3.8-flash-high)',
  '  --host <name>     host display name (default: Antigravity CLI)',
  '  --agy <path>      agy binary (default: agy on PATH)',
  '  --bwrap <path>    bwrap binary (default: bwrap on PATH)',
  '  --fixture <dir>   seed fixture (default: scripts/tests/fixtures/ce-capture/<probe-name>)',
  '  --work <dir>      work directory (default: a fresh directory under the system temp dir)',
  '  --timeout <ms>    wall-clock limit for the agy turn (default: 900000)',
  '  --model-canary    also run the two-arm model canary from the capture plan',
  '  --keep            keep the work directory',
  '  --print-plan      print the resolved plan and exit without running anything',
  '  --help            print this message',
].join('\n');

function usage() {
  process.stderr.write(USAGE + '\n');
  process.exit(2);
}

function fail(message) {
  process.stderr.write('capture-host-session: ' + message + '\n');
  process.exit(2);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    ...options,
  });
  return {
    status: result.status === null ? 124 : result.status,
    stdout: result.stdout ?? '',
    stderr: result.stderr ?? '',
    error: result.error,
  };
}

function mustRun(command, args, options = {}) {
  const result = run(command, args, options);
  if (result.status !== 0) {
    fail(command + ' ' + args.join(' ') + ' failed (exit ' + result.status + '): ' + (result.stderr || result.stdout).trim());
  }
  return result;
}

function which(binary) {
  const result = run('bash', ['-c', 'command -v ' + JSON.stringify(binary)]);
  const found = result.stdout.trim();
  return result.status === 0 && found ? found : '';
}

function isoLocal(date) {
  const pad = (n) => String(Math.floor(Math.abs(n))).padStart(2, '0');
  const offset = -date.getTimezoneOffset();
  const sign = offset >= 0 ? '+' : '-';
  return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate()) +
    'T' + pad(date.getHours()) + ':' + pad(date.getMinutes()) + ':' + pad(date.getSeconds()) +
    sign + pad(offset / 60) + ':' + pad(offset % 60);
}

// The `±HH:MM` label for a Date's host offset, in the same shape the renderer
// accepts as --offset. Recorded in provenance.json so a re-render is a property
// of the bundle rather than of whichever machine runs it.
function offsetLabel(date) {
  const pad = (n) => String(Math.floor(Math.abs(n))).padStart(2, '0');
  const offset = -date.getTimezoneOffset();
  const sign = offset >= 0 ? '+' : '-';
  return sign + pad(offset / 60) + ':' + pad(offset % 60);
}

function dateOnly(date) {
  const pad = (n) => String(n).padStart(2, '0');
  return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate());
}

// Reads a single-line section body out of a scenario file. The scenario format
// is fixed (## Prompt / ## Directive / ## Checks / ...), so this is a section
// reader rather than a Markdown parser.
function scenarioSection(text, heading) {
  const lines = text.split('\n');
  const body = [];
  let inside = false;
  for (const line of lines) {
    if (line.trim() === '## ' + heading) { inside = true; continue; }
    if (inside && line.startsWith('## ')) break;
    if (inside) body.push(line);
  }
  return body.join('\n').trim();
}

const argv = process.argv.slice(2);
if (argv.length === 0) usage();
if (argv[0] === '--help' || argv[0] === '-h') { process.stdout.write(USAGE + '\n'); process.exit(0); }

const positional = [];
const options = {
  model: 'gemini-3.8-flash-high',
  host: 'Antigravity CLI',
  agy: '',
  bwrap: '',
  fixture: '',
  work: '',
  timeout: 900000,
  modelCanary: false,
  keep: false,
  printPlan: false,
};

for (let i = 0; i < argv.length; i += 1) {
  const arg = argv[i];
  const value = argv[i + 1];
  switch (arg) {
    case '--model': if (value === undefined) usage(); options.model = value; i += 1; break;
    case '--host': if (value === undefined) usage(); options.host = value; i += 1; break;
    case '--agy': if (value === undefined) usage(); options.agy = value; i += 1; break;
    case '--bwrap': if (value === undefined) usage(); options.bwrap = value; i += 1; break;
    case '--fixture': if (value === undefined) usage(); options.fixture = value; i += 1; break;
    case '--work': if (value === undefined) usage(); options.work = value; i += 1; break;
    case '--timeout': if (value === undefined) usage(); options.timeout = Number(value); i += 1; break;
    case '--model-canary': options.modelCanary = true; break;
    case '--keep': options.keep = true; break;
    case '--print-plan': options.printPlan = true; break;
    case '--help': case '-h': process.stdout.write(USAGE + '\n'); process.exit(0); break;
    default:
      if (arg.startsWith('-')) fail('unknown argument: ' + arg);
      positional.push(arg);
  }
}

if (positional.length !== 2) usage();
const scenario = positional[0];
const bundleDir = path.resolve(positional[1]);

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, '..');
const scenarioPath = path.join(repoRoot, 'scripts/tests/eval-scenarios', scenario + '.md');
if (!fs.existsSync(scenarioPath)) fail('no such scenario: ' + scenarioPath);

const scenarioText = fs.readFileSync(scenarioPath, 'utf8');
const prompt = scenarioSection(scenarioText, 'Prompt');
const profile = scenarioSection(scenarioText, 'Directive');
if (!prompt) fail('scenario has no ## Prompt body: ' + scenarioPath);
if (profile !== 'balanced' && profile !== 'lite') fail('scenario ## Directive must be balanced or lite, got: ' + JSON.stringify(profile));

// The scenario name carries the profile as a suffix; the ## Directive body is
// authoritative, and a mismatch means the file and its name disagree.
const suffix = '-' + profile;
if (!scenario.endsWith(suffix)) fail('scenario name ' + scenario + ' does not end with ' + suffix + ' as its ## Directive body requires');
// The fixture is shared by the Balanced and Lite cells of a probe, so it is
// named without the profile suffix. The probe label that reaches the transcript,
// the README and state-check.json is the full scenario name: that is the cell
// identity a reader needs, and it is what the bundle directory is called.
const fixtureName = scenario.slice(0, -suffix.length);
const probe = scenario;

const fixtureDir = path.resolve(options.fixture || path.join(repoRoot, 'scripts/tests/fixtures/ce-capture', fixtureName));
if (!fs.existsSync(fixtureDir) || !fs.statSync(fixtureDir).isDirectory()) fail('no such fixture directory: ' + fixtureDir);

const agyPath = options.agy || which('agy');
const bwrapPath = options.bwrap || which('bwrap');
const rtkPath = which('rtk');

// Every host path is derived from the environment, never from a literal: this
// harness has to run on a machine whose operator is not this repository's
// author. A root or empty HOME cannot be isolated, so refuse it rather than
// mask nothing and call the result confinement.
const homeDir = os.homedir();
if (!homeDir || homeDir === '/' || homeDir === path.parse(homeDir).root) {
  fail('cannot isolate HOME: os.homedir() resolved to ' + JSON.stringify(homeDir));
}

const workDir = options.work ? path.resolve(options.work) : fs.mkdtempSync(path.join(os.tmpdir(), 'pk-capture-'));
const repoDir = path.join(workDir, 'repo');

// The sandbox gets a disposable HOME staged for this run only, so no host
// credential, global instruction file, MCP config, conversation log or
// Antigravity worktree is reachable from inside. Created after the
// --print-plan gate so planning stays filesystem-pure.
const captureHome = path.join(workDir, 'capture-home');
const ensureCaptureHome = () => fs.mkdirSync(captureHome, { recursive: true });

// The narrowest credential set that still lets agy authenticate: one OAuth
// token and one account id, bound read-only and only as files. The sibling
// directories that hold conversations, brain, worktrees and MCP configuration
// never enter the sandbox.
const CREDENTIAL_FILES = [
  '.gemini/antigravity-cli/antigravity-oauth-token',
  '.config/antigravity/credential-user-scope',
];
const credentialFiles = CREDENTIAL_FILES
  .map((rel) => path.join(homeDir, rel))
  .filter((file) => {
    try { return fs.statSync(file).isFile(); } catch { return false; }
  });

const agyArgs = [
  '--input-format', 'stream-json',
  '--output-format', 'stream-json',
  '--model', options.model,
  '--mode', 'accept-edits',
  '--dangerously-skip-permissions',
  '-p=',
];

// The confinement recipe from docs/internal/host-conformance/antigravity/README.md.
// Both HOME mounts are load-bearing: masking only the primary checkout leaves
// the answer key readable from the other copies on the machine, and the staged
// HOME keeps the host's credentials and Antigravity worktrees out of reach. The
// only read-write binds are the staged HOME and the fixture, so a session
// cannot write anywhere the host will keep.
function bwrapMountArgv() {
  const args = [
    '--dev-bind', '/', '/',
    '--tmpfs', homeDir,
    '--bind', captureHome, homeDir,
    '--tmpfs', '/tmp',
  ];
  // Mount sources are resolved on the host, so these file binds land inside the
  // staged HOME at their own $HOME-relative paths and nowhere else.
  if (agyPath) args.push('--ro-bind', agyPath, agyPath);
  if (rtkPath) args.push('--ro-bind', rtkPath, rtkPath);
  for (const file of credentialFiles) args.push('--ro-bind', file, file);
  return args;
}

function bwrapArgv(fixture, inner) {
  return bwrapMountArgv().concat(['--bind', fixture, fixture, '--chdir', fixture], inner);
}

const invocation = 'agy --input-format stream-json --output-format stream-json --model ' + options.model +
  ' --mode accept-edits --dangerously-skip-permissions (bwrap-isolated)';

if (options.printPlan) {
  process.stdout.write('CAPTURE_PLAN|scenario=' + scenario + '|probe=' + probe + '|profile=' + profile +
    '|fixture=' + fixtureDir + '|model=' + options.model + '|host=' + options.host + '|bundle=' + bundleDir + '\n');
  process.stdout.write('CAPTURE_PROMPT|' + prompt + '\n');
  process.stdout.write('CAPTURE_AGY|' + (agyPath || '(not found)') + '\n');
  process.stdout.write('CAPTURE_BWRAP|' + (bwrapPath || '(not found)') + '\n');
  process.stdout.write('CAPTURE_HOME|' + captureHome + '\n');
  process.stdout.write('CAPTURE_CREDENTIAL|' + (credentialFiles.length ? credentialFiles.join(',') : '(none)') + '\n');
  process.stdout.write('CAPTURE_MOUNTS|' + bwrapMountArgv().join(' ') + '\n');
  process.stdout.write('CAPTURE_INVOCATION|' + invocation + '\n');
  process.exit(0);
}

if (!agyPath) fail('agy not found on PATH; pass --agy <path>');
if (!bwrapPath) fail('bwrap not found on PATH; pass --bwrap <path>');
if (!credentialFiles.length) {
  process.stderr.write('capture-host-session: warning: no credential staged under ' + homeDir +
    '; agy may fail to authenticate inside the sandbox\n');
}

// ---------------------------------------------------------------------------
// Bundle scaffolding
// ---------------------------------------------------------------------------

fs.mkdirSync(bundleDir, { recursive: true });
fs.mkdirSync(workDir, { recursive: true });
ensureCaptureHome();

const bundle = (name) => path.join(bundleDir, name);
const write = (name, body) => fs.writeFileSync(bundle(name), body);

// A bundle's repository/ clone is rebuilt from repository.bundle, exactly as the
// opencode-omo bundles do it.
write('.gitignore', '# Rebuilt on demand from repository.bundle - see README.md. Never commit the clone itself.\nrepository/\n');

// ---------------------------------------------------------------------------
// 1. Seed the fixture
// ---------------------------------------------------------------------------

// A capture always starts from a clean worktree. cpSync merges into an existing
// directory, so a re-run over a leftover work dir would carry the previous
// run's staged kit into the seed commit and bury the install diff.
fs.rmSync(repoDir, { recursive: true, force: true });
fs.cpSync(fixtureDir, repoDir, { recursive: true });
// The fixture may carry its own .git from a previous run; a capture always
// starts from a fresh history.
fs.rmSync(path.join(repoDir, '.git'), { recursive: true, force: true });

const git = (args, options = {}) => mustRun('git', ['-C', repoDir, '-c', 'user.name=PromptKit Capture', '-c', 'user.email=capture@localhost'].concat(args), options);

git(['init', '-b', 'main']);
git(['add', '-A']);
git(['commit', '-m', 'seed: ' + probe + ' probe fixture']);
const seedCommit = git(['rev-parse', 'HEAD']).stdout.trim();

// ---------------------------------------------------------------------------
// 2. Stage the kit and install the directive
// ---------------------------------------------------------------------------

// The staged kit must not carry the answer key. A plain `git archive HEAD`
// ships scripts/tests/eval-scenarios/ce-*.md (the scenario files, rubric
// included), the scorer, docs/BEHAVIORAL-EVAL.md and the published bundles, so
// the model under test could read its own grading rubric. Measured on a real
// run: the model opened both the Balanced and the Lite scenario file and the
// scorer before answering, which makes its PASS worthless as discovery
// evidence. The exclusions below remove the rubric and keep the discovery route
// intact - protocols/context-economy.md, protocols/setup.md,
// docs/WORKFLOW-MAP.md and workflows/route.md all stay in the staged kit.
const KIT_EXCLUDES = [
  ':(exclude)scripts/tests',
  ':(exclude)scripts/run-behavioral-eval.sh',
  ':(exclude)scripts/run-behavioral-eval.ps1',
  ':(exclude)docs/BEHAVIORAL-EVAL.md',
  ':(exclude)docs/internal/host-conformance',
  ':(exclude)docs/tasks',
];

const kitTar = path.join(workDir, 'kit.tar');
mustRun('git', ['-C', repoRoot, 'archive', '--format=tar', 'HEAD', '-o', kitTar, '--', '.'].concat(KIT_EXCLUDES));
const kitDir = path.join(repoDir, '.promptkit');
fs.mkdirSync(kitDir, { recursive: true });
mustRun('tar', ['-xf', kitTar, '-C', kitDir]);

// Verify the exclusion instead of trusting it: a regression here silently
// invalidates every capture, so the run fails rather than publishing a bundle
// whose model could read the rubric.
const leakChecks = [
  ['scripts/tests/eval-scenarios', 'the scenario rubric'],
  ['scripts/run-behavioral-eval.sh', 'the scorer'],
  ['scripts/run-behavioral-eval.ps1', 'the scorer (PowerShell twin)'],
  ['docs/BEHAVIORAL-EVAL.md', 'the evaluation record'],
  ['docs/internal/host-conformance', 'the published bundles'],
  ['docs/tasks', 'the task records'],
];
const leakLines = ['# Kit staging exclusions - ' + scenario, '#', '# The staged kit is the tracked tree at promptkitCommit minus the paths below.', '# Each exclusion removes grading material the model under test must not read.', ''];
leakLines.push('$ git archive HEAD --format=tar -o kit.tar -- . ' + KIT_EXCLUDES.join(' '));
leakLines.push('');
for (const [rel, why] of leakChecks) {
  const present = fs.existsSync(path.join(kitDir, rel));
  leakLines.push((present ? 'LEAK' : 'absent') + '  ' + rel + '  (' + why + ')');
  if (present) {
    write('kit-exclusions.txt', leakLines.join('\n') + '\n');
    fail('staged kit still contains ' + rel + ' (' + why + '); the model could read its own rubric. See ' + bundle('kit-exclusions.txt'));
  }
}
// The discovery route must survive the pruning, or the capture measures nothing.
for (const rel of ['protocols/context-economy.md', 'protocols/setup.md', 'docs/WORKFLOW-MAP.md', 'workflows/route.md']) {
  const present = fs.existsSync(path.join(kitDir, rel));
  leakLines.push((present ? 'present' : 'MISSING') + '  ' + rel + '  (discovery route)');
  if (!present) {
    write('kit-exclusions.txt', leakLines.join('\n') + '\n');
    fail('staged kit is missing ' + rel + ', so the discovery route is broken and the capture would measure nothing. See ' + bundle('kit-exclusions.txt'));
  }
}
write('kit-exclusions.txt', leakLines.join('\n') + '\n');

// The kit is reproducible from promptkitCommit, so it stays out of the fixture's
// index. Committing it would add 2,459 files to the install diff and bury the
// directive the capture is about.
const excludePath = path.join(repoDir, '.git', 'info', 'exclude');
fs.mkdirSync(path.dirname(excludePath), { recursive: true });
fs.appendFileSync(excludePath, '\n.promptkit/\n');

const install = run('bash', ['.promptkit/init.sh', '--' + profile, '--host=gemini', '.'], {
  cwd: repoDir,
  env: { ...process.env, PROMPTKIT_NO_INTERACTIVE: '1', PROMPTKIT_NO_PREFLIGHT: '1' },
});
write('install.txt', '$ PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 bash .promptkit/init.sh --' + profile + ' --host=gemini .\n' +
  '[exit ' + install.status + ']\n--- stdout ---\n' + install.stdout + '--- stderr ---\n' + install.stderr);
if (install.status !== 0) fail('init.sh failed (exit ' + install.status + '); see ' + bundle('install.txt'));

git(['add', '-A']);
git(['commit', '-m', 'install: ' + (profile === 'lite' ? 'Lite' : 'Balanced') + ' directive via init.sh --host=gemini']);

// The directive file and the discovery target, recorded because the whole point
// of the capture is whether the model can reach protocols/context-economy.md.
const directiveLines = [];
const agentsPath = path.join(repoDir, 'AGENTS.md');
directiveLines.push('directive file: AGENTS.md');
directiveLines.push('AGENTS.md bytes: ' + (fs.existsSync(agentsPath) ? fs.statSync(agentsPath).size : 'absent'));
const protocolLine = fs.existsSync(agentsPath)
  ? (fs.readFileSync(agentsPath, 'utf8').split('\n').find((line) => line.includes('Protocols:')) || '(no protocol line)')
  : '(no AGENTS.md)';
directiveLines.push('protocol line: ' + protocolLine.trim());
const economyPath = path.join(kitDir, 'protocols/context-economy.md');
directiveLines.push('staged .promptkit/protocols/context-economy.md: ' + (fs.existsSync(economyPath) ? 'present (' + fs.statSync(economyPath).size + ' bytes)' : 'ABSENT'));
directiveLines.push('staged .promptkit/protocols/setup.md: ' + (fs.existsSync(path.join(kitDir, 'protocols/setup.md')) ? 'present' : 'ABSENT'));
directiveLines.push('staged .promptkit/workflows/route.md: ' + (fs.existsSync(path.join(kitDir, 'workflows/route.md')) ? 'present' : 'ABSENT'));
write('directive.txt', directiveLines.join('\n') + '\n');

const statusInitial = git(['status', '--porcelain']).stdout;
write('git-status-initial.txt', statusInitial);
if (statusInitial.trim()) fail('seeded worktree is not clean after install; see ' + bundle('git-status-initial.txt'));

// ---------------------------------------------------------------------------
// 3. Isolation canary
// ---------------------------------------------------------------------------

const canaryLines = [];
canaryLines.push('# Isolation canary - ' + scenario);
canaryLines.push('#');
canaryLines.push('# The canary passes only when the read FAILS. The unisolated arm is the');
canaryLines.push('# control: it must succeed, otherwise the canary proves nothing.');
canaryLines.push('#');
canaryLines.push('# The sweep is bounded and does NOT use -xdev. An earlier version ran');
canaryLines.push('# `find / -xdev`, which cannot descend into a different device - and the');
canaryLines.push('# bind-mounted fixture is a different device from /, so the canary could');
canaryLines.push('# not see the fixture even when the file was plainly readable. It reported');
canaryLines.push('# isolated=0 on every run, including runs where `cat` of the same file');
canaryLines.push('# succeeded. Arm 3 below tests readability directly for that reason.');
canaryLines.push('');

// Roots that can hold a checkout of this repository. A full `find /` without
// -xdev does not finish in a usable time on this host, so the sweep is bounded
// to the trees that actually carry copies.
const CANARY_ROOTS = ['/tmp', '/home', '/root', '/opt', '/srv', '/var/tmp', '/usr/local'];
const findCommand = 'find ' + CANARY_ROOTS.join(' ') + ' -name ' + JSON.stringify(scenario + '.md') + ' -print 2>/dev/null';

const unisolated = run('bash', ['-c', findCommand]);
const unisolatedPaths = unisolated.stdout.split('\n').filter(Boolean);
canaryLines.push('## Arm 1 - no isolation (control; a read here must succeed)');
canaryLines.push('$ ' + findCommand);
canaryLines.push('exit ' + unisolated.status + ', ' + unisolatedPaths.length + ' path(s)');
for (const p of unisolatedPaths.slice(0, 20)) canaryLines.push('  ' + p);
if (unisolatedPaths.length > 20) canaryLines.push('  ... ' + (unisolatedPaths.length - 20) + ' more');
canaryLines.push('');

const isolated = run(bwrapPath, bwrapArgv(repoDir, ['bash', '-c', findCommand]));
const isolatedPaths = isolated.stdout.split('\n').filter(Boolean);
canaryLines.push('## Arm 2 - bwrap isolation (the pass condition is an empty result)');
canaryLines.push('$ bwrap ' + bwrapArgv(repoDir, ['bash', '-c', findCommand]).join(' '));
canaryLines.push('exit ' + isolated.status + ', ' + isolatedPaths.length + ' path(s)');
for (const p of isolatedPaths.slice(0, 20)) canaryLines.push('  ' + p);
canaryLines.push('');

// Arm 3 is the arm that catches a blind canary. Arm 2 can only report what
// `find` chose to traverse; this arm asks the kernel directly whether a known
// copy is readable under the same confinement.
let directReadBlocked = null;
if (unisolatedPaths.length > 0) {
  const probePath = unisolatedPaths[0];
  const readCommand = 'cat ' + JSON.stringify(probePath) + ' >/dev/null 2>&1';
  const directRead = run(bwrapPath, bwrapArgv(repoDir, ['bash', '-c', readCommand]));
  directReadBlocked = directRead.status !== 0;
  canaryLines.push('## Arm 3 - bwrap isolation, direct read of a known copy (the pass condition is a failed read)');
  canaryLines.push('$ bwrap ... bash -c ' + JSON.stringify(readCommand));
  canaryLines.push('target: ' + probePath);
  canaryLines.push('exit ' + directRead.status + ', read ' + (directReadBlocked ? 'BLOCKED' : 'SUCCEEDED'));
  canaryLines.push('');
}

const controlFound = unisolatedPaths.length > 0;
const sweepClean = isolatedPaths.length === 0;
const directBlocked = directReadBlocked === true;
const canaryPassed = controlFound && sweepClean && directBlocked;
canaryLines.push('CANARY|' + (canaryPassed ? 'PASS' : 'FAIL') +
  '|unisolated=' + unisolatedPaths.length +
  '|isolated=' + isolatedPaths.length +
  '|direct-read=' + (directReadBlocked === null ? 'not-run' : (directReadBlocked ? 'blocked' : 'readable')));
if (!controlFound) canaryLines.push('# FAIL: the control arm found no copy, so the canary proves nothing.');
if (!sweepClean) canaryLines.push('# FAIL: the isolated sweep still found the scenario file.');
if (directReadBlocked === false) canaryLines.push('# FAIL: a known copy was readable under bwrap even though the sweep was clean.');
if (directReadBlocked === null) canaryLines.push('# FAIL: the control arm found nothing, so the direct-read arm could not run.');

// The model-level canary from the capture plan, section 3.2: ask the model to
// read a known file inside the kit checkout and report its first line. It runs
// in its own session so it never pollutes the capture transcript.
if (options.modelCanary) {
  const canaryPrompt = 'Read the file ' + scenarioPath + ' and reply with its first line, verbatim. ' +
    'If you cannot read it, reply with exactly: CANARY-READ-FAILED';
  const canaryEvent = JSON.stringify({ event: 'user', message: { role: 'user', content: canaryPrompt } }) + '\n';
  const arms = [
    ['Arm 4 - model canary, no isolation (control)', null],
    ['Arm 5 - model canary, bwrap isolation (the pass condition is a failed read)', bwrapArgv(repoDir, [agyPath].concat(agyArgs))],
  ];
  for (const [label, argvForArm] of arms) {
    const result = argvForArm
      ? run(bwrapPath, argvForArm, { input: canaryEvent, timeout: options.timeout })
      : run(agyPath, agyArgs, { input: canaryEvent, timeout: options.timeout, cwd: repoDir });
    let response = '';
    for (const line of result.stdout.split('\n')) {
      if (!line.trim()) continue;
      try {
        const event = JSON.parse(line);
        if (event.event === 'result' && event.result) response = event.result.response || '';
      } catch { /* not a JSON line */ }
    }
    const readSucceeded = response.includes('# Scenario ' + scenario);
    canaryLines.push('## ' + label);
    canaryLines.push('exit ' + result.status + ', read ' + (readSucceeded ? 'SUCCEEDED' : 'FAILED'));
    canaryLines.push('response: ' + JSON.stringify(response.trim().slice(0, 400)));
    canaryLines.push('');
  }
}

write('canary.txt', canaryLines.join('\n') + '\n');
if (!canaryPassed) {
  const reasons = [];
  if (!controlFound) reasons.push('the control arm found no copy of the scenario file, so the canary proves nothing');
  if (!sweepClean) reasons.push('the isolated sweep still found the scenario file');
  if (directReadBlocked === false) reasons.push('a known copy was readable under bwrap');
  if (directReadBlocked === null) reasons.push('the direct-read arm could not run');
  fail('isolation canary failed: ' + reasons.join('; ') + '. See ' + bundle('canary.txt'));
}

// ---------------------------------------------------------------------------
// 4. Drive agy
// ---------------------------------------------------------------------------

const userEvent = JSON.stringify({ event: 'user', message: { role: 'user', content: prompt } }) + '\n';
const observationStart = new Date();
const capture = run(bwrapPath, bwrapArgv(repoDir, [agyPath].concat(agyArgs)), {
  input: userEvent,
  timeout: options.timeout,
});
const observationEnd = new Date();

write('session.jsonl', capture.stdout);
write('session.stderr.txt', capture.stderr);

let resultEvent = null;
let conversationId = '';
for (const line of capture.stdout.split('\n')) {
  if (!line.trim()) continue;
  try {
    const event = JSON.parse(line);
    // agy puts conversation_id on the event itself, not inside the init payload.
    if (event.event === 'init') conversationId = event.conversation_id || (event.init && event.init.conversation_id) || conversationId;
    if (event.event === 'result' && event.result) resultEvent = event.result;
  } catch { /* not a JSON line */ }
}

// The transcript timeline is a reconstruction: agy reports no per-event clock, so
// each entry is placed by the capture start plus the cumulative step durations the
// stream does report. That start is recorded here rather than inferred from the
// stream file mtime, because git does not preserve mtime and a committed bundle
// re-rendered on another machine would shift every timestamp while the
// timestamp-stripped round-trip test still passed.
//
// The anchor is observationStart itself - the instant immediately before agy was
// spawned - rounded to whole milliseconds so the recorded value reproduces the
// same bytes on any filesystem. It is deliberately NOT derived from
// observationEnd minus the reported duration: that approximation drifts by the
// harness's own overhead, and on the two-turn resume capture it placed the
// timeline outside the observation window the same bundle records.
const timelineStart = new Date(Math.round(observationStart.getTime())).toISOString();

// ---------------------------------------------------------------------------
// 5. Post-session repository state
// ---------------------------------------------------------------------------

const finalHead = git(['rev-parse', 'HEAD']).stdout.trim();
write('final-head.txt', finalHead + '\n');
write('git-status-final.txt', git(['status', '--porcelain']).stdout);
write('diff-seed-to-head.txt', git(['diff', '--stat', seedCommit, 'HEAD']).stdout);
write('diff-staged.txt', git(['diff', '--cached', '--stat']).stdout);
write('diff-unstaged.txt', git(['diff', '--stat']).stdout);
write('untracked.txt', git(['ls-files', '--others', '--exclude-standard']).stdout);

const statePath = path.join(repoDir, 'docs/STATE.md');
write('state-at-end.md', fs.existsSync(statePath) ? fs.readFileSync(statePath, 'utf8') : '# docs/STATE.md absent at the end of the session\n');

// These two are milestone-halt artifacts. This probe has no Gated Mode Task
// Record, so they carry an explicit not-applicable body rather than an empty
// file that could be mistaken for a missing artifact.
const notApplicable = [
  '# Not applicable - the ' + probe + ' probe has no Gated Mode Task Record,',
  '# so there is no milestone 2 to advance into. See',
  '# ../../opencode-omo/milestone-halt/m2-paths.txt for the artifact this',
  '# file carries when the probe does have one.',
].join('\n') + '\n';
write('m2-paths.txt', notApplicable);
write('observed-m2-writes.txt', notApplicable);
write('state-check.json', JSON.stringify({
  applicable: false,
  probe,
  reason: "This probe's fixture has no Gated Mode Task Record, so m1Verified, signoffCallout and m2Advanced are not defined. state-check.json is a milestone-halt artifact; see ../../opencode-omo/milestone-halt/state-check.json.",
}, null, 2) + '\n');

mustRun('git', ['-C', repoDir, 'bundle', 'create', bundle('repository.bundle'), '--all']);

// ---------------------------------------------------------------------------
// 6. Derive the relative stream
// ---------------------------------------------------------------------------

// agy reports absolute paths. The scorer's repo-unwritten check cannot resolve
// an absolute write target and reports unjudgeable rather than passing, so an
// absolute stream would silently degrade a real violation to UNTESTED. The
// rewrite is a spelling change only: the raw stream is preserved as
// session.jsonl and the derivation is recorded in provenance.json.
const rawStream = fs.readFileSync(bundle('session.jsonl'), 'utf8');
const relativeStream = rawStream.split(repoDir + '/').join('').split(repoDir).join('.');
write('session.relative.jsonl', relativeStream);

// ---------------------------------------------------------------------------
// 7. Provenance and isolation record
// ---------------------------------------------------------------------------

const promptkitCommit = mustRun('git', ['-C', repoRoot, 'rev-parse', '--short=7', 'HEAD']).stdout.trim();
const agyVersion = run(agyPath, ['--version']).stdout.trim() || 'unknown';

const provenance = {
  captureDate: dateOnly(observationStart),
  promptkitCommit,
  profile,
  seedCommit,
  resetCommands: [
    'git init -b main',
    'copy the ' + fixtureName + ' fixture from scripts/tests/fixtures/ce-capture/' + fixtureName + ' into the worktree',
    "git add -A; git commit -m 'seed: " + probe + " probe fixture'",
    'git -C <promptkit checkout> archive --format=tar HEAD -- . ' + KIT_EXCLUDES.join(' ') + ' | tar -xf - -C .promptkit',
    'echo .promptkit/ >> .git/info/exclude',
    'PROMPTKIT_NO_INTERACTIVE=1 PROMPTKIT_NO_PREFLIGHT=1 bash .promptkit/init.sh --' + profile + ' --host=gemini .',
    "git add -A; git commit -m 'install: directive via init.sh --host=gemini'",
    'git status --porcelain must be empty',
    'run the isolation canary from docs/internal/host-conformance/antigravity/README.md (must report 0 paths)',
    'drive agy over --input-format stream-json inside the bwrap invocation recorded in isolation.txt',
  ].join('; '),
  hostName: options.host,
  hostVersion: 'agy ' + agyVersion,
  agentModel: options.model + ' (--mode accept-edits, --dangerously-skip-permissions); single-turn stream-json over stdin; bwrap-isolated',
  timelineStart,
  observationStart: isoLocal(observationStart),
  observationEnd: isoLocal(observationEnd),
  // The UTC offset the transcript's timestamp column is rendered in. Recorded
  // here because the renderer must never read the host zone: without this the
  // same bundle renders `+13:00` on the capture host and `+00:00` on a UTC CI
  // runner, and the committed transcript becomes unreproducible off the machine
  // that wrote it. observationStart carries the same offset; this field states
  // it as the rendering input rather than leaving it to be inferred.
  timelineOffset: offsetLabel(observationStart),
};
write('provenance.json', JSON.stringify(provenance, null, 2) + '\n');

write('isolation.txt', [
  '# Isolation configuration - ' + scenario,
  '#',
  '# Reproduce with the bwrap invocation below. Both HOME mounts are',
  '# load-bearing: masking only the primary checkout leaves the answer key',
  '# readable from the other copies on the machine, and the staged HOME keeps',
  '# host credentials, global instructions and Antigravity worktrees out of',
  '# reach. The staged HOME must exist before the run:',
  '#   mkdir -p ' + captureHome,
  '',
  '$ bwrap ' + bwrapArgv(repoDir, [agyPath].concat(agyArgs)).join(' '),
  '',
  '# stdin (one NDJSON line):',
  userEvent.trim(),
  '',
  '# canary: see canary.txt',
].join('\n') + '\n');

// ---------------------------------------------------------------------------
// 8. Render and score
// ---------------------------------------------------------------------------

// Scoring runs last on purpose. provenance_verified() reads provenance.json from
// the bundle directory, so scoring before provenance.json exists would record
// provenance=unverified for a bundle that is in fact complete.
const render = run('bash', [
  path.join(repoRoot, 'scripts/render-capture-transcript.sh'),
  bundle('session.relative.jsonl'),
  bundle('transcript.md'),
  bundle('observed-writes.log'),
  '--probe', probe,
  '--prompt', prompt,
  '--model', options.model,
  '--host', options.host,
  '--invocation', invocation,
  '--stream', 'session.relative.jsonl',
  '--start', timelineStart,
  '--offset', offsetLabel(observationStart),
]);
if (render.status !== 0) fail('renderer failed (exit ' + render.status + '): ' + render.stderr.trim());

const score = run('bash', [path.join(repoRoot, 'scripts/run-behavioral-eval.sh'), '--score', scenario, bundle('transcript.md')]);
write('scorer.txt', score.stdout + (score.stderr ? '--- stderr ---\n' + score.stderr : ''));
const verdictLine = score.stdout.split('\n').find((line) => line.startsWith(scenario + '|')) || '(no verdict line)';

const toolLines = fs.existsSync(bundle('observed-writes.log'))
  ? fs.readFileSync(bundle('observed-writes.log'), 'utf8').split('\n').filter(Boolean)
  : [];
const writeLines = toolLines.filter((line) => !/^tool (read|ls|grep|find) /.test(line));

const BT = String.fromCharCode(96);
const fence = BT + BT + BT;
write('README.md', [
  '# Live Capture - ' + options.host + ', ' + BT + probe + BT + ' probe (' + profile + ')',
  '',
  '- **Result: ' + BT + verdictLine.split('|')[2] + BT + '** - ' + BT + verdictLine + BT,
  '- **Host:** ' + options.host + ' ' + agyVersion + ', model ' + BT + options.model + BT + ', single-host - see *Scope* below.',
  '- **Captured:** ' + dateOnly(observationStart) + ', from a fresh isolated session seeded at ' + BT + seedCommit.slice(0, 7) + BT + '.',
  '',
  'This is a genuine live capture. The transcript was produced by a model session, not written by hand; the raw event stream is preserved verbatim as ' + BT + 'session.jsonl' + BT + ', and ' + BT + 'transcript.md' + BT + ' is rendered mechanically from ' + BT + 'session.relative.jsonl' + BT + ' by the same procedure for every line.',
  '',
  BT + 'session.relative.jsonl' + BT + ' is ' + BT + 'session.jsonl' + BT + ' with the capture root rewritten out of tool targets. agy reports absolute paths, and the scorer cannot resolve an absolute write target - it reports unjudgeable rather than passing - so an absolute stream would silently degrade a real violation to UNTESTED. The rewrite is a spelling change only and is recorded in ' + BT + 'provenance.json' + BT + '.',
  '',
  '## Prompt',
  '',
  fence + 'text',
  prompt,
  fence,
  '',
  '## What the model actually did',
  '',
  '- Tool calls recorded: ' + toolLines.length + '.',
  '- Non-inspection tool calls: ' + writeLines.length + '.',
  '- Session: ' + BT + (conversationId || 'unknown') + BT + ', status ' + BT + (resultEvent ? resultEvent.status : 'no result event') + BT + ', ' + (resultEvent ? resultEvent.num_turns : '?') + ' turn(s).',
  '',
  '## Evidence',
  '',
  '| Evidence | Value |',
  '| --- | --- |',
  '| Scorer verdict | ' + BT + verdictLine + BT + ' |',
  '| Isolation canary | ' + BT + (canaryPassed ? 'PASS' : 'FAIL') + BT + ' - ' + isolatedPaths.length + ' path(s) under bwrap, control found ' + unisolatedPaths.length + ', direct read ' + (directReadBlocked ? 'blocked' : 'readable') + ' (see ' + BT + 'canary.txt' + BT + ') |',
  '| Kit exclusions | ' + BT + 'kit-exclusions.txt' + BT + ' - the staged kit omits the scenario rubric, the scorer, this evaluation record, the published bundles and the task records |',
  '| Raw stream | ' + BT + 'session.jsonl' + BT + ' (' + fs.statSync(bundle('session.jsonl')).size + ' bytes) |',
  '| Rendered transcript | ' + BT + 'transcript.md' + BT + ' |',
  '| Kit commit | ' + BT + promptkitCommit + BT + ' |',
  '| Profile | ' + BT + profile + BT + ' |',
  '',
  '## Scope',
  '',
  'Single host, single model, one turn. This is an n=1 pilot: it is evidence that the behaviour occurred in this cell, not a conformance claim about the host, the model, or the profile. The confound rule in ' + BT + 'docs/HOST-CONFORMANCE.md' + BT + ' section 1 applies.',
  '',
].join('\n'));

if (!options.keep) fs.rmSync(workDir, { recursive: true, force: true });

process.stdout.write('CAPTURE|' + scenario + '|' + verdictLine + '\n');
process.stdout.write('CAPTURE_CANARY|' + (canaryPassed ? 'PASS' : 'FAIL') + '\n');
process.stdout.write('CAPTURE_BUNDLE|' + bundleDir + '\n');
process.exit(score.status === 0 ? 0 : 1);
