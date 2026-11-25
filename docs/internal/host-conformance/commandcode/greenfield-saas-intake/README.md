# Command Code CLI — greenfield-saas-intake capture

```
greenfield-saas-intake|live|PASS|checks=2/2|provenance=verified
```

**Behaviour**: Ran intake before architecture: asked the discovery questions and named an MVP floor instead of opening with a stack, so the `not-contains` check on a premature framework commitment stays clear.

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
