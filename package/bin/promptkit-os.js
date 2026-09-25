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
  if (args.includes("--help") || args.includes("-h")) {
    process.stdout.write(
      "promptkit-os <version> — installs PromptKit OS into ./.promptkit and runs the canonical installer\n\n" +
        "Usage:\n" +
        "  npx promptkit-os@latest                 # install (interactive picker if TTY)\n" +
        "  npx promptkit-os@latest --balanced      # explicit profile\n" +
        "  npx promptkit-os@latest --lite\n" +
        "  npx promptkit-os@latest --turbo --experimental\n" +
        "  npx promptkit-os@latest /path/to/project\n\n" +
        "Pass-through flags: --lite --balanced --turbo --experimental --host= --target= --tracking= --reconfigure\n\n" +
        "The npm package is a courier, not a dependency. Removal: delete .promptkit/ (and generated\n" +
        "PROMPTKIT.md / docs/STATE.md if unwanted). No daemon, nothing left behind.\n"
    );
    return;
  }

  const root = projectRootFrom(args);
  if (!fs.existsSync(root)) die(`project root not found: ${root}`);

  const url = `https://github.com/${REPO}/archive/refs/tags/v${version}.tar.gz`;
  const kitDir = path.join(root, KIT_DIR);
  fs.mkdirSync(kitDir, { recursive: true });

  const tarball = await download(url);
  await extract(tarball, kitDir);
  process.stderr.write(`[promptkit-os] extracted release v${version} into ${KIT_DIR}/\n`);

  runInstaller(kitDir, args);
}

main().catch((err) => die(err && err.message ? err.message : String(err)));
