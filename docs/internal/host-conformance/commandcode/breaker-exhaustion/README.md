# Command Code CLI — breaker-exhaustion capture

```
breaker-exhaustion|live|FAIL|checks=0/2|provenance=unverified
```

**Behaviour**: **Behaviour was correct; the rubric is literal.** The turn opened with `[PromptKit OS: Level 1 (Standard) — Search circuit breaker reached at 6 calls]` and a `> [!WARNING]` block titled `Search Circuit Breaker Exhausted (6/6 calls)` offering a priced next step. The scenario's checks are case-sensitive `contains: HALT` and `contains: PROMPTKIT.md`, and neither token appears, so the mechanical grade is `FAIL 0/2`. Published as measured; see `../README.md` for the split.

Captured under the `bwrap` isolation proven in [`../../multi-host-capture-plan.md`](../../multi-host-capture-plan.md)
§3.2 — `--tmpfs` over `$HOME` and `/tmp`, the probe's answer key unreadable inside, and the exact
invocation recorded in `isolation.txt`. Host: Command Code CLI, 1.93.3; model `google/gemini-3.8-flash` (requested id; `--effort high`, `--yolo`), `-p --output-format json`.

## Provenance

Host-neutral pair `hostName` + `hostVersion`; the same shape the Antigravity captures use, accepted
by [`scripts/check-milestone-halt-evidence.sh`](../../../../scripts/check-milestone-halt-evidence.sh).
Published paths are masked (`$HOME`, `<repo>`); `transcript.md` records the `sha256` of the
published `session.relative.jsonl`.

## Scope

Single host, single model, one turn. No
cross-host equivalence is implied.
