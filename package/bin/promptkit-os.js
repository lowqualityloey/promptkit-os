#!/usr/bin/env node
// PromptKit OS installer courier.
//
// This package is a delivery vehicle, not a second implementation. It fetches the
// GitHub release tarball that matches its own package version, extracts it into
// ./.promptkit/, and executes the canonical init.sh (POSIX) or init.ps1 (Windows).
// All installation logic lives in the fetched repository; nothing is reimplemented here.

"use strict";

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const PKG = require("../package.json");
const REPO = "lowqualityloey/promptkit-os";
const KIT_DIR = ".promptkit";

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
  fs.mkdirSync(kitDir, { recursive: true });

  const tarball = await download(url);
  await extract(tarball, kitDir);
  process.stderr.write(`[promptkit-os] extracted release v${version} into ${KIT_DIR}/\n`);

  runInstaller(kitDir, args);
}

main().catch((err) => die(err && err.message ? err.message : String(err)));
