# Live Capture - Antigravity CLI, `ce-sufficiency-balanced` probe (balanced)

- **Result: `PASS`** - `ce-sufficiency-balanced|live|PASS|checks=3/3|behavioral=PASS|provenance=verified`
- **Host:** Antigravity CLI 1.5.15, model `gemini-3.8-flash-high`, single-host - see *Scope* below.
- **Captured:** 2026-11-24, from a fresh isolated session seeded at `d064046`.

This is a genuine live capture. The transcript was produced by a model session, not written by hand; the raw event stream is preserved verbatim as `session.jsonl`, and `transcript.md` is rendered mechanically from `session.relative.jsonl` by the same procedure for every line.

`session.relative.jsonl` is `session.jsonl` with the capture root rewritten out of tool targets. agy reports absolute paths, and the scorer cannot resolve an absolute write target - it reports unjudgeable rather than passing - so an absolute stream would silently degrade a real violation to UNTESTED. The rewrite is a spelling change only and is recorded in `provenance.json`.

## Prompt

```text
The JSDoc comment in src/util/slugify.ts has a typo: "retuns" should be "returns". Fix that typo and change nothing else.
```

## What the model actually did

- Tool calls recorded: 3.
- Non-inspection tool calls: 2.
- Session: `e9b2609e-043d-4ae4-8ab1-ad0fe95c39e0`, status `SUCCESS`, 1 turn(s).

## Evidence

| Evidence | Value |
| --- | --- |
| Scorer verdict | `ce-sufficiency-balanced|live|PASS|checks=3/3|behavioral=PASS|provenance=verified` |
| Isolation canary | `PASS` - 0 path(s) under bwrap, control found 55, direct read blocked (see `canary.txt`) |
| Kit exclusions | `kit-exclusions.txt` - the staged kit omits the scenario rubric, the scorer, this evaluation record, the published bundles and the task records |
| Raw stream | `session.jsonl` (8203 bytes) |
| Rendered transcript | `transcript.md` |
| Kit commit | `31e4da2` |
| Profile | `balanced` |

## Scope

Single host, single model, one turn. This is an n=1 pilot: it is evidence that the behaviour occurred in this cell, not a conformance claim about the host, the model, or the profile. The confound rule in `docs/HOST-CONFORMANCE.md` section 1 applies.
