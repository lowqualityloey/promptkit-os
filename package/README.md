# `promptkit-os` (npm)

The open-source engineering control plane for AI coding agents (Claude Code, Cursor, Copilot, Antigravity, Gemini CLI) — managing task ceremony levels (L0–L3), context economy, JIT stack playbooks, and evidence-gated verification.

> **Note**: This npm package is the **courier**, not the product. PromptKit OS itself is pure repository-native markdown with no runtime, no daemon, and no model lock-in — it lives at [lowqualityloey/promptkit-os](https://github.com/lowqualityloey/promptkit-os).

This package does one thing: fetch the GitHub release tarball that matches its own version, extract it into `./.promptkit/`, and run the canonical `init.sh` (POSIX) or `init.ps1` (Windows). All installation logic stays in the fetched repository; nothing is reimplemented here.

## Install

```bash
npx promptkit-os@latest                 # interactive picker when in a TTY
npx promptkit-os@latest --balanced      # explicit profile
npx promptkit-os@latest --lite
npx promptkit-os@latest --turbo --experimental
npx promptkit-os@latest /path/to/project
```

Pass-through flags: `--lite`, `--balanced`, `--turbo`, `--experimental`, `--host=`, `--target=`, `--tracking=`, `--reconfigure`.

Requires Node 18+ (the courier runs on Node; the installed product does not). On Windows it also requires **PowerShell 7 (`pwsh`)**, which is what `init.ps1` targets — stock Windows PowerShell 5.1 is not supported.

## Updating an existing install

If `.promptkit/` already exists and is not empty, the courier **refuses to overlay it** — a tarball merge can leave stale files behind and mix delivery doors. The right update path depends on how it was installed:

```bash
# git-submodule install
git submodule update --remote --merge .promptkit && bash .promptkit/init.sh

# courier install (replace the existing tree; new couriers verify the archive)
rm -rf .promptkit
npx promptkit-os@latest --balanced
```

The courier detects which case applies (a submodule install has `.promptkit/.git`) and prints the matching command. `--force` overlays anyway, but it is not recommended.

## Version pinning

`npx promptkit-os@X.Y.Z` fetches the GitHub archive for tag `vX.Y.Z`, not a branch head. New couriers require a valid SHA-256 digest for their own version before download and verify the archive **before** creating `.promptkit/`, extracting files, or running the installer. The release workflow independently checks the tagged archive, injects the digest, and checks the actual npm-packed courier before publication. A missing or mismatched digest stops installation; it is not a warning-only path.

**Historical exception:** the already-published immutable npm courier `promptkit-os@1.11.0` did not contain its own archive pin and warns/proceeds by default. npm package integrity/provenance authenticates that npm tarball, **not** the second-stage GitHub archive it downloads. Existing installed files are not retroactively checked or changed by the new policy. For `1.11.0`, an operator can independently obtain a trusted archive SHA-256 and set both `PROMPTKIT_TARBALL_SHA256=<trusted-64-hex-sha256>` and `PROMPTKIT_REQUIRE_INTEGRITY_PIN=1` (in PowerShell, set `$env:PROMPTKIT_TARBALL_SHA256` and `$env:PROMPTKIT_REQUIRE_INTEGRITY_PIN`); the published courier verifies the override before extraction. New couriers also accept an explicitly supplied trusted `PROMPTKIT_TARBALL_SHA256` for archive rotation. The override is an **operator-controlled trust input**: do not derive it from the same untrusted download, and investigate a mismatch rather than disabling verification.

GitHub-generated tag archives are not guaranteed byte-for-byte immutable forever. A legitimate archive-regeneration change may require a separately verified override or a new courier release; a fixed tag name alone does not guarantee reproducible archive bytes.

## Removal

Delete `.promptkit/` — plus the generated `PROMPTKIT.md` and `docs/STATE.md` if you don't want them. No daemon, no cache, no registration, nothing left behind.

## Which path should I use?

The git submodule flow remains canonical and is documented first in the [README](https://github.com/lowqualityloey/promptkit-os#readme) and [QUICKSTART](https://github.com/lowqualityloey/promptkit-os/blob/main/QUICKSTART.md). Use npm when you want a one-command install without submodule ceremony; the resulting `.promptkit/` tree is identical either way.

## License

MIT. Not affiliated with `microsoft/PromptKit` or `erikgeiser/promptkit`.
