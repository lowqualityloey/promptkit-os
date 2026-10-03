#!/usr/bin/env node
// PromptKit OS installer courier.
//
// This package is a delivery vehicle, not a second implementation. It fetches the
// GitHub release tarball that matches its own package version, extracts it into
// ./.promptkit/, and executes the canonical init.sh (POSIX) or init.ps1 (Windows).
// All installation logic lives in the fetched repository; nothing is reimplemented here.

"use strict";

const { spawnSync } = require("node:child_process");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const PKG = require("../package.json");
const REPO = "lowqualityloey/promptkit-os";
const KIT_DIR = ".promptkit";

// Pinned SHA-256 (hex) of the GitHub release tarball per courier version.
// This lives here — not in a sidecar file — because release-npm.yml enforces an
// npm-pack allowlist of exactly { package.json, README.md, bin/promptkit-os.js };
// a sidecar would either be excluded from the published package (useless) or
// require a workflow change to allowlist.
//
// Release pins are inserted and checked by the repository release workflow after
// it checks out the tag and before npm publication. Do not mint pins by hand. If
// no pin exists for the running version, the courier warns and continues (pins can
// only be minted after the tag exists); set PROMPTKIT_REQUIRE_INTEGRITY_PIN=1 to
// fail closed. PROMPTKIT_TARBALL_SHA256 overrides the map for testing or rotation.
//
// CAVEAT: these digests pin GitHub's *generated* archive for a tag. That archive
// is reproducible today (verified by double download when each pin was minted)
// but is not contractually immutable — a future GitHub-side change to archive
// generation would change the bytes and make this pin reject an untampered
// download. On mismatch, confirm the release tag and the release evidence
// record before treating it as tampering; rotate with PROMPTKIT_TARBALL_SHA256.
const TARBALL_SHA256_BY_VERSION = {
  "1.10.1": "1e55459914a1c46aa71df8f9cb8ce4c9ff37d1c02d67f70e5607b3bfd4f48d4b",
  "1.11.0": "6503fdfcde286055b8c053aa0ffa8bdf244cf77df3321cccd6a8d8f780195ade",
  // @pin-insert
};

function die(msg) {
  process.stderr.write(`[promptkit-os] ${msg}\n`);
  process.exit(1);
}

function passthroughFlags(argv) {
  const known = new Set([
    "--lite",
    "--balanced",
    "--turbo",
    "--experimental",
    "--reconfigure",
    "-h",
    "--help",
  ]);
  const out = [];
  for (const arg of argv) {
    if (arg === "--force") continue; // courier-only flag, never forwarded to the installer
    if (known.has(arg) || arg.startsWith("--host=") || arg.startsWith("--target=") || arg.startsWith("--tracking=")) {
      out.push(arg);
    } else if (!arg.startsWith("-")) {
      out.push(arg); // positional project root
    } else {
      die(`unknown flag '${arg}' — pass it through after the install target, or see init --help`);
    }
  }
  return out;
}

// Extracting a tarball over an existing tree is not idempotent the way the canonical
// git-submodule path is: it merges, leaving stale files behind and producing a franken
// state that mixes delivery doors. Refuse instead, and say exactly how to proceed —
// the correct update command depends on which door produced the existing install.
function assertInstallTargetIsClean(kitDir, force) {
  if (!fs.existsSync(kitDir)) return;
  const entries = fs.readdirSync(kitDir);
  if (entries.length === 0 || force) return;

  const isSubmoduleInstall = fs.existsSync(path.join(kitDir, ".git"));
  const update = isSubmoduleInstall
    ? "  git submodule update --remote --merge .promptkit && bash .promptkit/init.sh"
    : `  rm -rf ${KIT_DIR}\n` +
      `  npx promptkit-os@latest --balanced   # or: npx promptkit-os@latest --lite`;
  const updateIntro = isSubmoduleInstall
    ? "To update this git-submodule install:"
    : "To update this courier install, replace it (the tarball is pinned per version):";

  die(
    `${KIT_DIR}/ already exists and is not empty.\n` +
      "            Refusing to overlay it — a tarball merge can leave stale files behind.\n" +
      `            ${updateIntro}\n` +
      update +
      "\n            To force an overlay anyway (not recommended), re-run with --force."
  );
}

function projectRootFrom(args) {
  const positional = args.filter((a) => !a.startsWith("-"));
  return path.resolve(positional[0] || process.cwd());
}

function expectedTarballDigest(version) {
  const override = process.env.PROMPTKIT_TARBALL_SHA256;
  if (override !== undefined && override !== "") return override;
  return TARBALL_SHA256_BY_VERSION[version];
}

// Aborts (non-zero exit, no extract, no exec) unless `tarball` hashes to
// `expectedHex`. Comparison is constant-time so a MITM learns nothing about the
// pin from timing. Must be called after download() and before extract().
function verifyTarballIntegrity(tarball, expectedHex, version) {
  const actual = crypto.createHash("sha256").update(tarball).digest();
  const expected = Buffer.from(String(expectedHex), "hex");
  // Buffer.from(hex) never throws on bad input — it truncates — so the length
  // check below is what turns a malformed pin into a mismatch (fail closed).
  if (expected.length !== actual.length || !crypto.timingSafeEqual(actual, expected)) {
    die(
      `tarball integrity mismatch for v${version} ` +
        `(expected sha256 ${expectedHex}, got ${actual.toString("hex")}): ` +
        "refusing to extract or execute — the download may have been tampered with. " +
        "If this version was just released, the pin in TARBALL_SHA256_BY_VERSION needs updating (see above)."
    );
  }
}

async function download(url) {
  process.stderr.write(`[promptkit-os] fetching ${url}\n`);
  const res = await fetch(url, { redirect: "follow" });
  if (!res.ok) die(`download failed (HTTP ${res.status}) for ${url}`);
  return Buffer.from(await res.arrayBuffer());
}

async function extract(tarball, dest) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "promptkit-os-"));
  const tarPath = path.join(tmp, "release.tar.gz");
  fs.writeFileSync(tarPath, tarball);

  const res = spawnSync("tar", ["-xzf", tarPath, "-C", dest, "--strip-components=1"], { stdio: "inherit" });
  if (res.status !== 0) die("failed to extract release tarball (is `tar` available?)");
  fs.rmSync(tmp, { recursive: true, force: true });
}

function runInstaller(kitDir, args) {
  const isWindows = process.platform === "win32";
  if (isWindows) {
    const ps = path.join(kitDir, "init.ps1");
    if (!fs.existsSync(ps)) die("init.ps1 missing from release tarball");
    const res = spawnSync("pwsh", ["-NoProfile", "-File", ps, ...args], { stdio: "inherit" });
    if (res.status !== 0) die("init.ps1 failed");
  } else {
    const sh = path.join(kitDir, "init.sh");
    if (!fs.existsSync(sh)) die("init.sh missing from release tarball");
    fs.chmodSync(sh, 0o755);
    const res = spawnSync("bash", [sh, ...args], { stdio: "inherit" });
    if (res.status !== 0) die("init.sh failed");
  }
}

async function main() {
  const version = PKG.version;
  if (version === "0.0.0") {
    die(
      "this build is unreleased (version 0.0.0) — install a published version instead:\n" +
        "            npx promptkit-os@latest --balanced"
    );
  }

  const args = passthroughFlags(process.argv.slice(2));
  const force = process.argv.slice(2).includes("--force");
  if (args.includes("--help") || args.includes("-h")) {
    process.stdout.write(
      "promptkit-os <version> — installs PromptKit OS into ./.promptkit and runs the canonical installer\n\n" +
        "Usage:\n" +
        "  npx promptkit-os@latest                 # install (interactive picker if TTY)\n" +
        "  npx promptkit-os@latest --balanced      # explicit profile\n" +
        "  npx promptkit-os@latest --lite\n" +
        "  npx promptkit-os@latest --turbo --experimental\n" +
        "  npx promptkit-os@latest /path/to/project\n\n" +
        "Pass-through flags: --lite --balanced --turbo --experimental --host= --target= --tracking= --reconfigure\n" +
        "Courier flags: --force (overlay a non-empty .promptkit/; not recommended)\n\n" +
        "Updating an existing install? Use the canonical path instead:\n" +
        "  git submodule update --remote --merge .promptkit && bash .promptkit/init.sh\n\n" +
        "The npm package is a courier, not a dependency. Removal: delete .promptkit/ (and generated\n" +
        "PROMPTKIT.md / docs/STATE.md if unwanted). No daemon, nothing left behind.\n"
    );
    return;
  }

  const root = projectRootFrom(args);
  if (!fs.existsSync(root)) die(`project root not found: ${root}`);

  const url = `https://github.com/${REPO}/archive/refs/tags/v${version}.tar.gz`;
  const kitDir = path.join(root, KIT_DIR);
  assertInstallTargetIsClean(kitDir, force);

  const tarball = await download(url);
  const expectedDigest = expectedTarballDigest(version);
  if (expectedDigest) {
    verifyTarballIntegrity(tarball, expectedDigest, version);
    process.stderr.write(`[promptkit-os] verified release tarball integrity (sha256) for v${version}\n`);
  } else if (process.env.PROMPTKIT_REQUIRE_INTEGRITY_PIN === "1") {
    die(
      `no integrity pin for v${version} — refusing to extract or execute. ` +
        "Add the sha256 of the release tarball to TARBALL_SHA256_BY_VERSION (see above)."
    );
  } else {
    process.stderr.write(
      `[promptkit-os] warning: no integrity pin for v${version}; ` +
        "proceeding unverified — set PROMPTKIT_REQUIRE_INTEGRITY_PIN=1 to fail closed.\n"
    );
  }
  fs.mkdirSync(kitDir, { recursive: true });
  await extract(tarball, kitDir);
  process.stderr.write(`[promptkit-os] extracted release v${version} into ${KIT_DIR}/\n`);

  runInstaller(kitDir, args);
}

if (require.main === module) {
  main().catch((err) => die(err && err.message ? err.message : String(err)));
} else {
  module.exports = { verifyTarballIntegrity, expectedTarballDigest, TARBALL_SHA256_BY_VERSION };
}
