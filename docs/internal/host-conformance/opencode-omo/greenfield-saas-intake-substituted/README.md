# OpenCode — greenfield-saas-intake capture (model substituted)

```
greenfield-saas-intake|live|PASS|checks=2/2|provenance=unverified
```

**Behaviour**: Ran intake before architecture: the turn asked the discovery questions and refused to name a stack before scope, clearing the premature-framework `not-contains` check.

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
