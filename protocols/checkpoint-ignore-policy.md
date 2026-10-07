# Checkpoint Ignore Policy Protocol

## Purpose

Define how `pk:checkpoint` makes invisibility visible when a checkpoint target sits behind a repository author's `.gitignore` rule. The protocol is read-only: it reports ignored targets as evidence and never overrides publication policy. Stage, commit, force-add, `!`-negation, and any index or `.gitignore` mutation are explicitly out of scope for `pk:checkpoint`.

A `.gitignore` rule is the repository author's declaration of what they choose to publish. `pk:checkpoint` does not negotiate it: it records the rule source verbatim, names the `POLICY_LIMITATION`, and lets the human choose the remedy. A tracked file is visible to Git, so a matching ignore pattern does not apply to it and is not reported.

---

## Execution Steps

### 1. Preflight Evidence Command (Bash and PowerShell twins)

Run the kit's local preflight to enumerate ignored checkpoint targets. The script is shipped as a Bash / PowerShell twin pair per CONTRIBUTING.md's "Behavioral Contract & Parity" rule:

```bash
bash scripts/check-checkpoint-ignore.sh [--root PATH] [--targets-file PATH]
```

```powershell
pwsh -NoProfile -File scripts/check-checkpoint-ignore.ps1 [-Root PATH] [-TargetsFile PATH]
```

Default targets are read from `scripts/checkpoint-targets.txt`, one `path|kind` per row with kind `file` or `dir`. Blank lines and `#`-prefixed comments are skipped; every other row must be exactly `path|kind` with a non-empty path containing no `|` and kind `file` or `dir`. A row with no pipe, an unknown kind, an empty path, or an extra pipe makes the run print `CHECKPOINT_IGNORE|INCOMPLETE|RULES|<row with |, CR and LF replaced by spaces>` and exit `2`, never a silent skip. A `dir` row is checked as the directory itself (its path with one trailing slash, e.g. `docs/tasks/`) and as each existing direct `*.md` file under it; both probes count in `SCANNED` (and in `IGNORED` when matched). The shipped file also carries two prospective-record probe rows, `docs/tasks/pk-probe.checkpoint-1.md|file` and `docs/tasks/pk-probe.handoff-1.md|file`, so an ignore rule that would hide a not-yet-written `docs/tasks/<task-id>.checkpoint-<n>.md` or `<task-id>.handoff-<n>.md` is reported before the record exists; a rule keyed on one specific task ID is not caught.
A project may pass `--targets-file` to point at its own rules file. A missing targets file is `INCOMPLETE`, never a silent pass. This preflight is the sole executable evidence of ignore status; `scripts/validate-execution-control.*` stays git-free and never performs the git checks itself.

### 2. Output and Exit Codes

Per ignored target, the preflight prints one line:

```text
POLICY_LIMITATION|CHECKPOINT_IGNORE|<path>|Checkpoint target is ignored by <source:line:pattern>|...
```

The summary line and exit code depend on the result:

| Summary | Meaning | Exit code |
| :--- | :--- | :---: |
| `CHECKPOINT_IGNORE|NO_FINDINGS|SCANNED=<n>` | Nothing ignored; behaviour is unchanged from today | 0 |
| `CHECKPOINT_IGNORE|DEGRADED|IGNORED=<n>|SCANNED=<n>` | One or more targets ignored; the record is still written, reported not halted | 0 |
| `CHECKPOINT_IGNORE|INCOMPLETE|<reason>|<path or row>` | Preflight could not measure ignore status | 2 |

`reason` is one of `RULES`, `GIT_METADATA`, or `GIT_IGNORE`:
- `RULES` — the targets file is missing or unreadable, or a row is malformed (`path|kind` violated, as in step 1); the fourth field holds the sanitized offending row. Never coerce to a silent pass.
- `GIT_METADATA` — no repository metadata is available to answer.
- `GIT_IGNORE` — git returned an exit code other than `0` or `1`, or could not be launched at all. Status `2` is never reported as `OK`; it is `INCOMPLETE`.

A tracked path is not reported, even when a pattern would match it, because Git already considers it visible.

### 3. Evidence Block Wording

When the preflight reports `CHECKPOINT_IGNORE|DEGRADED`, the Phase 4 evidence block of `pk:checkpoint` (`workflows/checkpoint.md`, anchor: `### Phase 4: docs/STATE.md Sync & Handover Prompt Generation`) copies the preflight's `POLICY_LIMITATION|CHECKPOINT_IGNORE` line, which preserves the `git check-ignore -v` output as `source:line:pattern` (for example `.gitignore:1:docs/`), with any CR, LF, or `|` character replaced by a space so the line stays machine-parseable. The two human remedies are quoted in the same block:

- the author adds a `!` negation exception to the rule that matches the path; or
- the author relocates the artifact out of the ignored path.

`pk:checkpoint` performs neither. The script never calls `git add`, `git add -f`, `git commit`, or any index or `.gitignore` mutation. A regression lock asserts the checkpoint run produced no index change (`git diff --cached --name-only` is unchanged); that lock lives in the test fixtures, not in this protocol.

### 4. Scope Boundary (Mode A only)

This protocol covers Mode A: Git cannot see the file because the author placed it behind an ignore rule. It does not cover Mode B (the agent stopped writing the file because it judged the gate unsatisfiable). Mode B is owned by issue #553 (progressive compliance) and is exposed via the Level 1 (Standard) `quick` tier of `workflows/checkpoint.md` (anchor: `Level 1 (Standard): quick tier.`), where a degradable record path with `POLICY_LIMITATION` marks already exists for unsatisfiable checkpoints. Do not restate those rules here.