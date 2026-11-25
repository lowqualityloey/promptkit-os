# OpenCode — breaker-exhaustion capture (model substituted)

```
breaker-exhaustion|live|FAIL|checks=0/2|provenance=unverified
```

**Behaviour**: **Behaviour was correct; the rubric is literal.** The turn halted and explained that six consecutive searches had produced no edit, but it wrote the breaker state in lower case and never named `PROMPTKIT.md`, so the case-sensitive `contains: HALT` and `contains: PROMPTKIT.md` checks both miss. Published as `FAIL 0/2` exactly as measured.

Captured under the `bwrap` isolation proven in [`../../multi-host-capture-plan.md`](../../multi-host-capture-plan.md)
§3.2 — `--tmpfs` over `$HOME` and `/tmp`, the probe's answer key unreadable inside, and the exact
invocation recorded in `isolation.txt`. Host: OpenCode, v2.4.1; model `opencode/deepseek-v4.1-flash-free` (model substituted — see `../README.md`), `--standalone --format json`.

## Provenance

Host-neutral pair `hostName` + `hostVersion`; the same shape the Antigravity captures use, accepted
by [`scripts/check-milestone-halt-evidence.sh`](../../../../scripts/check-milestone-halt-evidence.sh).
Published paths are masked (`$HOME`, `<repo>`); `transcript.md` records the `sha256` of the
published `session.relative.jsonl`.

## Scope

Single host, single model, one turn. No
cross-host equivalence is implied.
