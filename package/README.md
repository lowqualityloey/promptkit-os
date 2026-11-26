# `promptkit-os` (npm)

The open-source advisory instruction layer for AI coding agents (Claude Code, Cursor, Windsurf, GitHub Copilot, Cline/Roo Code, Trae, OpenCode, Aider, Gemini CLI/Antigravity) — covering task ceremony levels (L0–L3), context economy, JIT stack playbooks, and evidence-gated verification.

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

Pass-through flags: `--lite`, `--balanced`, `--solo-fast`, `--turbo`, `--experimental`, `--host=`, `--add-host=`, `--target=`, `--tracking=`, `--reconfigure`. Courier-only flags: `--update` and `--force`.

Requires Node 18+ (the courier runs on Node; the installed product does not) — the courier checks at startup and prints a clear error on older runtimes instead of failing on a missing `fetch`. On Windows it also requires **PowerShell 7 (`pwsh`)**, which is what `init.ps1` targets — stock Windows PowerShell 5.1 is not supported.

> The `version` in this repository's `package/package.json` is intentionally `0.0.0`: the release workflow stamps the real version from the git tag and mints the tarball integrity pin at publish time (`docs/internal/release-evaluation.md` §1 records the mechanics). Running the courier from an unstamped checkout refuses with a clear error.

## Updating an existing install

If `.promptkit/` already exists and is not empty, the courier **refuses to overlay it** — a tarball merge can leave stale files behind and mix delivery doors. The right update path depends on how it was installed:

```bash
# courier install — download, SHA-verify, extract to a staging tree, then swap
# atomically with rollback on failure
npx promptkit-os@latest --update

# git-submodule install
git submodule update --remote --merge .promptkit && bash .promptkit/init.sh
```

`--update` is courier-only: it refuses when `.promptkit/.git` exists and points you at the submodule command, refuses a missing `.promptkit/`, and is mutually exclusive with `--force`. Without `--update` the courier detects which case applies and prints the matching command. `--force` overlays anyway, but it is not recommended.

## Version pinning

`npx promptkit-os@X.Y.Z` fetches the GitHub archive for tag `vX.Y.Z`, not a branch head. New couriers require a valid SHA-256 digest for their own version before download and verify the archive **before** creating `.promptkit/`, extracting files, or running the installer. The release workflow independently checks the tagged archive, injects the digest, and checks the actual npm-packed courier before publication. A missing or mismatched digest stops installation; it is not a warning-only path.

**Historical exception:** the already-published immutable npm courier `promptkit-os@1.11.0` did not contain its own archive pin and warns/proceeds by default. npm package integrity/provenance authenticates that npm tarball, **not** the second-stage GitHub archive it downloads. Existing installed files are not retroactively checked or changed by the new policy. For `1.11.0`, an operator can independently obtain a trusted archive SHA-256 and set both `PROMPTKIT_TARBALL_SHA256=<trusted-64-hex-sha256>` and `PROMPTKIT_REQUIRE_INTEGRITY_PIN=1` (in PowerShell, set `$env:PROMPTKIT_TARBALL_SHA256` and `$env:PROMPTKIT_REQUIRE_INTEGRITY_PIN`); the published courier verifies the override before extraction. New couriers also accept an explicitly supplied trusted `PROMPTKIT_TARBALL_SHA256` for archive rotation. The override is an **operator-controlled trust input**: do not derive it from the same untrusted download, and investigate a mismatch rather than disabling verification.

GitHub-generated tag archives are not guaranteed byte-for-byte immutable forever. A legitimate archive-regeneration change may require a separately verified override or a new courier release; a fixed tag name alone does not guarantee reproducible archive bytes.

## Removal

First remove PromptKit's directive blocks from every host file the installer wrote to: `bash .promptkit/init.sh --strip-directives` (PowerShell: `pwsh -File .promptkit/init.ps1 --strip-directives`). It removes only complete `<!-- PROMPTKIT_START -->` … `<!-- PROMPTKIT_END -->` blocks, preserves your own content and line endings, deletes a host file only when nothing else was in it, and never touches `PROMPTKIT.md`, `docs/STATE.md`, or `.promptkit/`; add `--dry-run` to preview. Then delete `.promptkit/` — a courier install needs nothing else, while a submodule install must be unregistered first as the main README describes. Delete the generated `PROMPTKIT.md` and `docs/STATE.md` only if you don't want them. No daemon, no cache, no registration, nothing left behind.

## Which path should I use?

The git submodule flow remains canonical and is documented first in the [README](https://github.com/lowqualityloey/promptkit-os#readme) and [QUICKSTART](https://github.com/lowqualityloey/promptkit-os/blob/main/QUICKSTART.md). Use npm when you want a one-command install without submodule ceremony; the resulting `.promptkit/` tree is identical either way.

## License

MIT. Not affiliated with `microsoft/PromptKit` or `erikgeiser/promptkit`.
