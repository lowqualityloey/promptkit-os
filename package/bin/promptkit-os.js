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
// it checks out the tag and before npm publication. Do not mint pins by hand. A
// missing or invalid own-version pin fails closed before download. An explicitly
// supplied PROMPTKIT_TARBALL_SHA256 overrides the map as an operator-controlled
// trust input for testing or archive rotation.
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
  // Historical pins for the published v2.x cohort, recovered from the npm courier
  // tarballs of each release and verified against the current GitHub tag archive
  // (sha256 + scripts/verify-release-archive.py --commit <tag>). They exist so an
  // explicitly requested older courier version still has an auditable pin instead
  // of failing closed with "no integrity pin".
  "2.0.0": "4fb5b9d85e0f19bfe333c361e00465705b60636a8026edd62c15c6f2d61cbf4b",
  "2.0.1": "6f3d667346bbc8cdc42e916fafcbde5dd0e42753398fe528609bf990ea35365b",
  "2.1.0": "44a8a25e16c7abf31b412b8129ecead8bf1f0d1e3c75deb7d1cb1059d1ba9b17",
  "2.2.0": "fbc1106938e0588a68566dea231a468d1915596746d103ddf19bfd861697475d",
  "2.3.0": "47242231bfb6fb677922a4bbce8fdf8fda32570275a4807c3f4d721a046bd01c",
  "2.4.0": "58a36d4a62222ef8a3136cd2bd5add0508885f9005e8766efaa09fc7dc308718",
  "2.5.0": "ee09bc0a83977ecaaf29ab8b3a699f84b0d0a0094d72bbbb363e2269a2d80a1a",
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
    "--solo-fast",
    "--reconfigure",
    "-h",
    "--help",
  ]);
  const out = [];
  for (const arg of argv) {
    if (arg === "--force" || arg === "--update") continue; // courier-only flags, never forwarded to the installer
    if (known.has(arg) || arg.startsWith("--host=") || arg.startsWith("--add-host=") || arg.startsWith("--target=") || arg.startsWith("--tracking=")) {
      out.push(arg);
    } else if (!arg.startsWith("-")) {
      out.push(arg); // positional project root
    } else {
      die(`unknown flag '${arg}' — the courier forwards a fixed allowlist; run the installer directly for full flags (init.sh --help / init.ps1 --help)`);
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

function assertUpdatable(kitDir) {
  if (!fs.existsSync(kitDir)) {
    die(`no ${KIT_DIR}/ to update — run npx promptkit-os@latest without --update to make a fresh install`);
  }
  if (fs.existsSync(path.join(kitDir, ".git"))) {
    die(
      `${KIT_DIR}/ is a git-submodule install, not a courier install — update it in place:
` +
        "  git submodule update --remote --merge .promptkit && bash .promptkit/init.sh"
    );
  }
}

// The install door is a plain directory owned by the project root. lstat is
// deliberate: existsSync follows links, so a dangling .promptkit symlink would
// read as "absent" and a fresh install would be laid down through the link.
// --force would rmSync the link's target entries and --update would rename the
// link itself, so both doors are refused for anything that is not a real
// directory, and the resolved parent must still be the resolved project root.
function kitTargetKind(kitDir, root) {
  let stat;
  try {
    stat = fs.lstatSync(kitDir);
  } catch (err) {
    if (err.code === "ENOENT") return "absent";
    throw err;
  }
  if (stat.isSymbolicLink()) {
    die(`${KIT_DIR}/ is a symbolic link — refusing to install, overlay or update through it; nothing was changed. Remove the link and re-run.`);
  }
  if (!stat.isDirectory()) {
    die(`${KIT_DIR}/ exists but is not a directory — refusing to install, overlay or update through it; nothing was changed.`);
  }
  const canonicalRoot = fs.realpathSync(root);
  const canonicalParent = path.dirname(fs.realpathSync(kitDir));
  const same = process.platform === "win32"
    ? canonicalRoot.toLowerCase() === canonicalParent.toLowerCase()
    : canonicalRoot === canonicalParent;
  if (!same) {
    die(`${KIT_DIR}/ does not resolve inside the project root — refusing to install, overlay or update through it; nothing was changed.`);
  }
  return "directory";
}

function projectRootFrom(args) {
  const positional = args.filter((a) => !a.startsWith("-"));
  return path.resolve(positional[0] || process.cwd());
}

function normalizedDigest(digest, version) {
  if (typeof digest !== "string" || !/^[0-9a-fA-F]{64}$/.test(digest)) {
    die(`invalid SHA-256 digest for v${version} — expected exactly 64 hexadecimal characters; refusing to download, extract or execute`);
  }
  return digest.toLowerCase();
}

function expectedTarballDigest(version) {
  const override = process.env.PROMPTKIT_TARBALL_SHA256;
  const digest = override === undefined ? TARBALL_SHA256_BY_VERSION[version] : override;
  if (digest === undefined) {
    die(`no integrity pin for v${version} — refusing to download, extract or execute; supply a trusted PROMPTKIT_TARBALL_SHA256`);
  }
  return normalizedDigest(digest, version);
}

// Aborts (non-zero exit, no extract, no exec) unless `tarball` hashes to
// `expectedHex`. Comparison is constant-time. Must be called after download()
// and before extract().
function verifyTarballIntegrity(tarball, expectedHex, version) {
  const expected = Buffer.from(normalizedDigest(expectedHex, version), "hex");
  const actual = crypto.createHash("sha256").update(tarball).digest();
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
  let res;
  try {
    res = await fetch(url, { redirect: "follow", signal: AbortSignal.timeout(30_000) });
  } catch (err) {
    die(`download failed for ${url}: ${err && err.message ? err.message : String(err)}`);
  }
  if (!res.ok) die(`download failed (HTTP ${res.status}) for ${url}`);
  return Buffer.from(await res.arrayBuffer());
}

function extractToStaging(tarball, root) {
  const staging = fs.mkdtempSync(path.join(root, `${KIT_DIR}-staging-`));
  try {
    const stagedTarball = path.join(staging, ".promptkit-release.tar.gz");
    fs.writeFileSync(stagedTarball, tarball);

    const res = spawnSync("tar", ["-xzf", ".promptkit-release.tar.gz", "--strip-components=1"], { cwd: staging, stdio: "inherit" });
    if (res.error) {
      const hint = res.error.code === "ENOENT" ? "tar not found on PATH" : res.error.message;
      throw new Error(`failed to extract release tarball: ${hint} (no changes were made to ${KIT_DIR}/)`);
    }
    if (res.status !== 0) {
      throw new Error(`failed to extract release tarball (tar exit ${res.status ?? res.signal}) (no changes were made to ${KIT_DIR}/)`);
    }
    fs.rmSync(stagedTarball, { force: true });
    return staging;
  } catch (err) {
    fs.rmSync(staging, { recursive: true, force: true });
    throw err;
  }
}

function extract(tarball, root, dest, options = {}) {
  // Re-check the door here as well: the download is asynchronous, so the target
  // could be swapped for a symlink between the main() guard and this mutation.
  kitTargetKind(dest, root);
  // Extract into a sibling staging directory and only publish it after tar exits 0.
  // A tar failure (missing binary, corrupt/truncated archive, full disk) then leaves no
  // partially written .promptkit/ and no staging leftovers, so an immediate retry
  // starts clean. Staging is created inside `root` so the final rename stays on the
  // same filesystem.
  //
  // Every tar operand must also stay relative: GNU tar — the first `tar` on PATH inside
  // Git Bash — reads `C:\...` operands as remote host:path and dies with
  // "Cannot connect to C: resolve failed", so the older staging-temp-dir + absolute -C
  // form broke the Windows leg wherever Git Bash leads PATH. Extracting with
  // cwd=staging and a relative archive name leaves no absolute path in argv at all,
  // on GNU tar, bsdtar, and POSIX tar alike.
  const staging = extractToStaging(tarball, root);
  try {
    if (options.replace) {
      // --update replaces the whole tree instead of merging, so a file removed
      // upstream cannot survive in the consumer's copy. The old tree is moved
      // aside first and restored if the rename or chmod fails.
      const backup = path.join(root, `${KIT_DIR}-backup-${process.pid}-${Date.now()}`);
      const hadDest = fs.existsSync(dest);
      if (hadDest) fs.renameSync(dest, backup);
      try {
        fs.renameSync(staging, dest);
        fs.chmodSync(dest, 0o755);
      } catch (err) {
        fs.rmSync(dest, { recursive: true, force: true });
        if (hadDest) fs.renameSync(backup, dest);
        throw err;
      }
      if (hadDest) fs.rmSync(backup, { recursive: true, force: true });
    } else if (fs.existsSync(dest)) {
      // --force opts into the documented overlay: move each top-level entry over the
      // existing tree, replacing same-named entries so no stale file survives inside
      // them. tar has already succeeded, so a failed extraction never reaches this
      // block and never mutates the existing install.
      for (const entry of fs.readdirSync(staging)) {
        fs.rmSync(path.join(dest, entry), { recursive: true, force: true });
        fs.renameSync(path.join(staging, entry), path.join(dest, entry));
      }
      fs.rmSync(staging, { recursive: true, force: true });
    } else {
      fs.renameSync(staging, dest);
      fs.chmodSync(dest, 0o755);
    }
  } catch (err) {
    fs.rmSync(staging, { recursive: true, force: true });
    throw err;
  }
}

function runInstaller(kitDir, args) {
  const isWindows = process.platform === "win32";
  if (isWindows) {
    const ps = path.join(kitDir, "init.ps1");
    if (!fs.existsSync(ps)) die("init.ps1 missing from release tarball");
    const res = spawnSync("pwsh", ["-NoProfile", "-File", ps, ...args], { stdio: "inherit" });
    if (res.error) {
      const hint = res.error.code === "ENOENT"
        ? "pwsh not found — PowerShell 7 is required on Windows (aka.ms/powershell); or use the git-submodule door and run bash .promptkit/init.sh"
        : res.error.message;
      die(`failed to launch init.ps1: ${hint}`);
    }
    return res.status;
  } else {
    const sh = path.join(kitDir, "init.sh");
    if (!fs.existsSync(sh)) die("init.sh missing from release tarball");
    fs.chmodSync(sh, 0o755);
    const res = spawnSync("bash", [sh, ...args], { stdio: "inherit" });
    if (res.error) {
      const hint = res.error.code === "ENOENT"
        ? "bash not found — a POSIX shell is required to run init.sh"
        : res.error.message;
      die(`failed to launch init.sh: ${hint}`);
    }
    return res.status;
  }
}

function installerArgs(args, version) {
  return [...args, `--engine-version=v${version}`];
}

async function main() {
  const nodeMajor = parseInt(String(process.versions.node).split(".")[0], 10);
  if (nodeMajor < 18 || typeof fetch !== "function") {
    die(
      `Node 18+ is required (found ${process.versions.node}) — the courier uses global fetch.\n` +
        `            upgrade Node, or install via the canonical git submodule path:\n` +
        `            git submodule add https://github.com/${REPO}.git .promptkit && ./.promptkit/init.sh`
    );
  }
  const version = PKG.version;
  if (version === "0.0.0") {
    die(
      "this build is unreleased (version 0.0.0) — install a published version instead:\n" +
        "            npx promptkit-os@latest --balanced"
    );
  }

  const rawArgs = process.argv.slice(2);
  const args = passthroughFlags(rawArgs);
  const force = rawArgs.includes("--force");
  const update = rawArgs.includes("--update");
  if (args.includes("--help") || args.includes("-h")) {
    process.stdout.write(
`promptkit-os <version> — installs PromptKit OS into ./.promptkit and runs the canonical installer

Usage:
  npx promptkit-os@latest                 # install (interactive picker if TTY)
  npx promptkit-os@latest --balanced      # explicit profile
  npx promptkit-os@latest --lite
  npx promptkit-os@latest --turbo --experimental
  npx promptkit-os@latest /path/to/project
  npx promptkit-os@latest --update        # atomically replace this courier install

Pass-through flags: --lite --balanced --turbo --experimental --solo-fast --host= --add-host= --target= --tracking= --reconfigure
Courier flags: --force (overlay a non-empty .promptkit/; not recommended), --update (replace a courier install; refuses git-submodule installs)
Hosts: --host=codex targets AGENTS.md, the same file as the universal target.

Updating an existing install?
  npx promptkit-os@latest --update      # courier install (not a git submodule)
  git submodule update --remote --merge .promptkit && bash .promptkit/init.sh   # git-submodule install

The npm package is a courier, not a dependency. Removal: delete .promptkit/ (and generated
PROMPTKIT.md / docs/STATE.md if unwanted). No daemon, nothing left behind.
`
    );
    return;
  }
  if (update && force) {
    die("--update and --force are mutually exclusive — --update replaces a courier install with the release tarball; --force overlays an existing tree without removing stale files");
  }

  const root = projectRootFrom(args);
  if (!fs.existsSync(root)) die(`project root not found: ${root}`);

  const url = `https://github.com/${REPO}/archive/refs/tags/v${version}.tar.gz`;
  const kitDir = path.join(root, KIT_DIR);
  const freshInstall = kitTargetKind(kitDir, root) === "absent";
  if (update) assertUpdatable(kitDir);
  else assertInstallTargetIsClean(kitDir, force);

  const expectedDigest = expectedTarballDigest(version);
  const tarball = await download(url);
  verifyTarballIntegrity(tarball, expectedDigest, version);
  process.stderr.write(`[promptkit-os] verified release tarball integrity (sha256) for v${version}
`);
  extract(tarball, root, kitDir, { replace: update });
  process.stderr.write(`[promptkit-os] extracted release v${version} into ${KIT_DIR}/
`);

  const status = runInstaller(kitDir, installerArgs(args, version));
  const installerName = process.platform === "win32" ? "init.ps1" : "init.sh";
  if (status === 130) {
    // The canonical installers exit 130 when the user cancels. A fresh non-forced
    // courier run has created .promptkit/ only to run the installer, so remove it
    // and leave the project exactly as it was found. Never remove a pre-existing
    // install, and never remove one the user explicitly asked to overlay.
    if (freshInstall && !force) {
      fs.rmSync(kitDir, { recursive: true, force: true });
      process.stderr.write(`[promptkit-os] setup cancelled — removed the newly created ${KIT_DIR}/
`);
    } else {
      process.stderr.write(`[promptkit-os] setup cancelled — existing ${KIT_DIR}/ left unchanged
`);
    }
    process.exit(130);
  }
  if (status !== 0) die(`${installerName} failed (exit ${status})`);
  process.stderr.write(
    `[promptkit-os] ${KIT_DIR}/ is a courier copy with no upstream — commit it for a reproducible install, ` +
      `or add ${KIT_DIR}/ to .gitignore and reinstall with npx promptkit-os@latest; git submodule update does not apply.
`
  );
}

if (require.main === module) {
  main().catch((err) => die(err && err.message ? err.message : String(err)));
} else {
  module.exports = { verifyTarballIntegrity, expectedTarballDigest, TARBALL_SHA256_BY_VERSION, installerArgs };
}
