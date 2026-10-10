# Migrating from the Jev / System One Assisted Router

**Status:** This guide is the in-tree migration documentation for the v2.0.0 candidate. v2.0.0 remains DRAFT / PRELIMINARY / BLOCKED / NOT APPROVED. This document does not approve it, and it provides no new behavior or implementation capability of its own.

## What changed (E-MAJOR-01)

Before commit `e50d2bb`, `scripts/pk-route.sh` and `scripts/pk-route.ps1` could optionally consult an external Jev (System One) recommendation through the Vercel AI Gateway or a TypeSafe endpoint when `AI_GATEWAY_API_KEY` or `TYPESAFE_API_KEY` was set, falling back to deterministic offline routing otherwise. After the retirement:

- Routing is fully offline and deterministic. There is no network transport, no external service, and no credentials. The same prompt always yields the same level and workflow (current help text in both router twins).
- The external model recommendation is gone. No Jev output, no Jev-justified ceremony level, no gateway URL.
- Legacy credential env vars are ignored entirely, never read, never leaked, never contacted (`scripts/tests/run-pk-route-tests.sh` records this post-retirement contract).
- **No classification parity is promised** with the retired Jev-assisted path. Offline deterministic routing is a different behavior, not a drop-in recommendation equivalent. Do not assume a prompt that Jev routed one way classifies identically now.

The historical help text documented a transport fallback hierarchy and an Environment section naming both keys. The current help documents local pattern rules only; the deprecated-flag wording from its help is quoted under Compatibility flags below.

## Before and after

All transcripts below are quoted verbatim from captured runs, each labeled **Historical (pre-retirement)** or **Current**. Historical runs are from pre-retirement commit `50f0217` (the parent of `e50d2bb`) with credentials unset; current runs are from merged main `f5174b1`. In the captured output, the Bash twin's banner separator is an em dash (`—`) and the PowerShell twin's is an ASCII hyphen (`-`), in both eras; the hyphen is a capture-console artifact, since the banner strings in `scripts/pk-route.ps1` themselves use the em dash.

### Bash twin: `fix a typo in README`

Historical (pre-retirement), offline fallback with no keys:

```text
[PromptKit OS: Level 0 (Direct) — Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY). Zero overhead.]
Recommended Workflow: pk:fix
```

Current:

```text
[PromptKit OS: Level 0 (Direct) — Deterministic offline policy classification. Zero overhead.]
Recommended Workflow: pk:fix
```

### PowerShell twin: same prompt

Historical (pre-retirement):

```text
[PromptKit OS: Level 0 (Direct) - Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY). Zero overhead.]
Recommended Workflow: pk:fix
```

Current:

```text
[PromptKit OS: Level 0 (Direct) - Deterministic offline policy classification. Zero overhead.]
Recommended Workflow: pk:fix
```

### The removed keyed dry-run (historical only)

Historical (pre-retirement), Bash twin, dummy `AI_GATEWAY_API_KEY` plus `--dry-run`. The dry-run exited before any network call; the gateway line below was a plan projection, not a request:

```text
[DryRun] Would query Jev via gateway at https://ai-gateway.vercel.sh/v4/ai/evaluation-model (Timeout: 2s)
[PromptKit OS: Level 0 (Direct) — Dry-run deterministic projection. Zero overhead.]
Recommended Workflow: pk:fix
```

Today `--dry-run` is a deprecated compatibility no-op: no gateway line, no dry-run projection.

### Observed classification delta: a question ABOUT an action

Sample prompt: `what does releasing this package do?`

Historical (pre-retirement), Bash twin:

```text
[PromptKit OS: Level 1 (Standard) — Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY). No Task Record required.]
Recommended Workflow: pk:route
```

Current, Bash twin:

```text
[PromptKit OS: Level 0 (Direct) — Deterministic offline policy classification. Zero overhead.]
Recommended Workflow: pk:route
```

Both twins agree on this delta. The question no longer escalates: a request ABOUT an action is not a request to perform one. For the other captured sample prompts (README typo, schema change, release, dockerize-plus-rename), historical offline and current levels matched. Treat this as one observed delta on a bounded prompt set, not as a general equivalence or general divergence claim between the two routers.

### Level 2 still requires a Task Record

Sample prompt: `add a database migration for the billing schema`.

Current, Bash twin:

```text
[PromptKit OS: Level 2 (Controlled) — Deterministic offline policy classification. Task Record required.]
Recommended Workflow: pk:route
```

The historical twins produced the same Level 2 with the old offline-fallback reason string.

## Entry points

- `scripts/pk-route.sh` (Bash) and `scripts/pk-route.ps1` (PowerShell 7) classify a prompt directly.
- `scripts/pk route "<text>"` and `scripts/pk.ps1 route "<text>"` run the same classifier through a thin shim and propagate its exit code.

Only `route` is an executable entry point. Every other `pk:*` trigger is a file-level prompt contract resolving to `workflows/<name>.md`, read by your host agent; it is not a shell command. An unknown subcommand fails loudly with exit code 2:

```text
pk: unknown subcommand: frobnicate
File-level contract: workflows/frobnicate.md
Only `route` is an executable entry point; the other pk:* triggers are file-level prompt contracts, not shell commands.
```

This shim behavior is separate from the Jev retirement; do not conflate the two.

## Compatibility flags

Both twins keep the old flag names with new meanings:

| Bash | PowerShell | Behavior now |
| --- | --- | --- |
| `--timeout <sec>` | `-TimeoutSec <int>` | Deprecated compatibility no-op; accepted and ignored |
| `--dry-run` | `-DryRun` | Deprecated compatibility no-op; accepted and ignored |
| `--offline` | `-Offline` | Force offline deterministic classification (banner reason: `Forced offline deterministic routing`) |
| `--prompt <text>` | `-Prompt <text>` | Task or user prompt to classify |

Current Bash help, verbatim on the deprecated flags:

```text
  --timeout <sec>     Deprecated compatibility no-op; accepted and ignored
  --dry-run           Deprecated compatibility no-op; accepted and ignored
```

The current PowerShell help carries the same wording for `-TimeoutSec` and `-DryRun`.

Normal prompt handling differs per twin; do not generalize one twin's mechanism to the other:

- Bash: the prompt is a positional argument or `--prompt <text>`. Unrecognized arguments fall through to the option loop's default arm and are appended to the prompt, space-joined (`scripts/pk-route.sh`).
- PowerShell: the prompt is `-Prompt <text>` or positional remaining arguments collected via `ValueFromRemainingArguments` into `$PromptArgs` and joined with spaces (`scripts/pk-route.ps1`). The `pk.ps1` shim re-launches a fresh `pwsh` so router switches such as `-Offline` bind as named parameters instead of being swallowed into the prompt.

## L0–L3 changes

Canonical level names and ceremony rules live in `workflows/route.md`: Level 0 — Direct, Level 1 — Standard, Level 2 — Controlled, Level 3 — Release-Critical.

- **Deterministic precedence.** `emit_deterministic_route` in `scripts/pk-route.sh` evaluates hard Level 3 triggers first, then hard Level 2, then obvious Level 0; anything else is Level 1.
- **Questions about actions.** A question ABOUT an action no longer escalates on topical markers (the P4 delta above). The informational-frame rule is documented in both router sources.
- **Narrowed informational veto.** Commit `b33c648` fixed the veto swallowing real actions: `Docker` was demoted because it contains the substring `doc`, and `rename` was treated as an informational frame marker. Both regression cases now reach Level 3 ("Implement the high-impact public API in Docker.", "Rename the high-impact public API."), and a coordination marker followed by its own action verb ("explain ... then implement it") still escalates (`scripts/pk-route.sh`, `scripts/pk-route.ps1`; `scripts/tests/run-pk-route-tests.sh`).
- **0% unsafe-underclassification objective, fixture-scoped only.** The routers state a 0% Unsafe Underclassification Rate objective across the tested fixture set in `scripts/tests/run-pk-route-tests.sh` (and its PowerShell twin). That is a safety objective measured on those fixtures, not a proven property over unrestricted input, and not a universal guarantee.
- **Level 2 requires a Task Record** at `docs/tasks/<task-id>.md` before implementation (`workflows/route.md`, Level 2 — Controlled).
- **Level 3 requires explicit human authorization** before tagging, publishing, or deploying (`workflows/route.md`, Level 3 — Release-Critical).

## Upgrading

This section aligns with the draft upgrade-path bullets in the v2.0.0 evaluation record (section 7), with claims grounded in the courier source below.

### Clean up assumptions in your automation

- Remove `AI_GATEWAY_API_KEY` / `TYPESAFE_API_KEY` reads and exports that existed only for the router. The router ignores them now; keeping them implies a credential gate that no longer exists.
- Remove Jev timeout tuning and recommendation parsing. `--timeout` / `-TimeoutSec` and `--dry-run` / `-DryRun` are accepted and ignored; do not rely on them to alter routing, timing, or output.
- Re-validate any automation that parsed Jev-justified ceremony levels or the removed strings: the `Offline fallback (no AI_GATEWAY_API_KEY nor TYPESAFE_API_KEY)` reason, the `Dry-run deterministic projection` reason, and the `[DryRun] Would query Jev via gateway` line. The current router produces none of them.

### npm courier installs

The npm package is a courier, not a dependency (`package/README.md`, `package/bin/promptkit-os.js`):

- The courier resolves an archive SHA-256 pin for its own version **before downloading**. A missing pin refuses with exit 1 before any download; a digest mismatch refuses with exit 1 after download but before extraction or execution.
- `PROMPTKIT_TARBALL_SHA256` is an operator-trusted override: exactly 64 hexadecimal characters, and a defined-but-invalid value fails closed. Use only a digest obtained independently; never derive it from the download you are verifying.
- A non-empty `.promptkit/` is refused so a tarball cannot merge over an existing tree. `--force` overlays anyway and is not recommended; it can leave stale files behind.
- The already-published immutable `promptkit-os@1.11.0` predates the pin policy and still warns and proceeds by default. Publishing is not retroactive: that package's bytes do not change, and re-running any courier never verifies an already-installed tree.

### Git submodule installs

Update the submodule and re-run the canonical installer, as documented in [Updating PromptKit](../QUICKSTART.md#updating-promptkit):

```bash
git submodule update --remote --merge .promptkit
bash .promptkit/init.sh      # macOS/Linux
.\.promptkit\init.ps1        # Windows
```

Then run `pk:sync` in your next session so the agent hot-reloads the updated rules. Do not mix courier and submodule update methods on one install.

### Backups, local customizations, and rollback

- Back up owned or local customizations inside `.promptkit/` before replacing it; reinstall does not merge them back.
- For gradual-adoption patterns and conflict handling, see "Migration Strategies for Common Scenarios" in [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md).
- For removal, see "Rollback Plan" in [ADOPTION-GUIDE.md](ADOPTION-GUIDE.md). Nothing in this guide executes those steps for you.

## Limitations

- No universal host-conformance claim is made here.
- No universal underclassification guarantee is made; the 0% objective is scoped strictly to the tested fixture set.
- No claim is made that release-workflow smoke tests have passed; the release workflow has not run for this candidate.
- No parity with the retired Jev-assisted path is promised or implied.
- This document is documentation only. It provides no new behavior or implementation capability and approves nothing.
