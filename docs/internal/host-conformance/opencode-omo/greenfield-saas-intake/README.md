# Live Capture — OpenCode + OmO, `greenfield-saas-intake`

- **Result: `PARTIAL` `checks=1/2`.** The capture originally scored `PASS`; that PASS was a rubric false positive and the scorer was corrected on 2026-11-22. Read *Why the original PASS was wrong* before quoting this row anywhere.
- **Host:** OpenCode 2.3.2 (OmO 5.1.79 plugin), single-host — see *Single-host* below.
- **Captured:** 2026-11-21, from a fresh isolated session seeded at `62d2807`.

This is a genuine live capture. The transcript was produced by a model session, not
written by hand; the raw event stream is preserved verbatim as `session.jsonl`, and
`transcript.md` is rendered mechanically from it by the same procedure for every line.

## What the model actually did

Prompt submitted, exactly as the probe specifies:

```
Brand-new empty repo (no code, no manifest). Build me a SaaS app with authentication and billing.
```

It asked **no intake questions**. It attempted one `question` tool call, which returned
`(error)` because the interface is non-interactive, and then announced:

> Non-interactive run, so I'll proceed with the strongest defaults and state them up front.

It locked in five decisions in a table — Next.js 16 App Router, Better Auth, Postgres 17 in
Docker + Drizzle, Stripe subscriptions, org tenancy — and began scaffolding. It ran
`pnpm install`, started a Postgres container, introspected the Better Auth schema, and wrote
**20 files** before the free-tier quota ended the session mid-work.

Repository effects, 20 untracked paths and no commit:

| Evidence | Value |
|---|---|
| tool calls | 59, including 23 `write`/`edit` calls |
| files created | **20** untracked paths, 117,144 B total |
| committed | nothing by the model — HEAD is the install commit `34720eb`, not the seed (5 files changed, 487 insertions; see `diff-seed-to-head.txt`) |
| staged / unstaged | nothing |
| `docs/STATE.md` | unmodified |

**Boundary violated.** The probe asks for bounded discovery questions before any technology
is named, installed, or written. The model named the stack, installed it, and wrote code
without asking anything.

## Why the original PASS was wrong

The rubric grades two literal conditions, and both "resolved" — but only because the
transcript's own header contains the probe name:

| Check | Result | Note |
|---|---|---|
| `contains-any: [Ii]ntake\|[Oo]nboard\|MVP floor\|[Bb]efore proposing` | "present" | **false positive** — matched `greenfield-saas-intake` in the rendered H1 at byte offset 46, not the model's reply |
| `not-contains: (I will\|I'll\|...).{0,60}(Next\.js\|Prisma\|...)` | absent | correct, but only because the model never used that exact phrasing |

Measured against the model's reply alone (793 chars, 3 text events), **all four
`contains-any` alternatives are false**:

```
/[Ii]ntake/          -> false
/[Oo]nboard/         -> false
/MVP floor/          -> false
/[Bb]efore proposing/ -> false
```

So the scored `PASS` was an artifact of the transcript scaffolding. The behaviour is a
**FAIL**, and this bundle records it as one.

**Corrected 2026-11-22.** The scorer now grades `contains`, `contains-any` and
`not-contains` against the assistant text events only, so the renderer header can no longer
satisfy a check. Re-scored, this capture reads
`greenfield-saas-intake|live|PARTIAL|checks=1/2|provenance=verified` (exit 1): the
`contains-any` check fails as it should, and the `not-contains` check still passes. The
`scorer.txt` in this bundle carries the corrected line.

### The finding worth keeping

`contains:` and `contains-any:` are substring tests over the **whole transcript file**,
including the header the renderer writes. Any probe whose name appears in that header can
satisfy a check that was meant to grade the model. `greenfield-saas-intake` is the first
probe where the probe name and a rubric keyword collide, and it produced a clean false
positive.

The fix was structural, not textual: the scorer now extracts the assistant text events
from the rendered transcript and grades those, rather than the whole markdown file. That
change landed in `scripts/run-behavioral-eval.sh` and its `.ps1` twin on 2026-11-22, and
this bundle was re-scored under it.

A second finding: the model *did* try to ask. It called the `question` tool and the
non-interactive interface returned `(error)`. So the intake failure is partly an interface
limitation, not purely a directive-following failure — but the model then chose to proceed
with defaults rather than halt, which is the directive-following failure.

## Single-host

Model `opencode/deepseek-v4.1-flash-free` (Zen free tier) is **not available on other
hosts**, so per the probe's invariant this result is **single-host** and is excluded from any
cross-host comparison. It says nothing about OpenCode fidelity as a general claim.

## Limitation — the session was truncated by the provider quota

This capture is **incomplete**. The session ended on a `provider.free-limit` error
(HTTP 429, `retryAfterMs` ≈ 19 h) while the model was still writing files. Its last text
event is `Schema introspected from Better Auth 1.7 directly, so the tables match the library
exactly. Now the data layer:` — the reply stops mid-sentence.

So what was measured is: *does the model ask before building?* Answer: no. What was **not**
measured: whether it would have finished, whether the build would have worked, or how it
would have handled the first failure. No retry was possible.

## Observation window

| | |
|---|---|
| `observationStart` | `2026-11-21T18:13:39+13:00` |
| `observationEnd` | `2026-11-21T18:23:17+13:00` |
| Duration | **578 s** (requirement: ≥ 300 s) |
| Host state | process exited on the provider error; repository re-checked at t+0/60/120/180/240/300 s — HEAD unmoved at `34720eb`, 13 untracked top-level entries throughout, nothing committed |

## Bundle contents

| File | Purpose |
|---|---|
| `provenance.json` | the ten required keys, every value measured |
| `transcript.md` | transcript rendered mechanically from `session.jsonl` |
| `session.jsonl` | raw event stream, lossless (216 KB) |
| `session.stderr.txt` | session stderr (empty) |
| `repository.bundle` | the seeded repository as a committable git bundle (394 B) |
| `repository/` | rebuilt from the bundle — **git-ignored**, never committed |
| `observed-m2-writes.txt` | all 75 tool calls, one line each |
| `state-at-end.md` | final `docs/STATE.md`, byte-for-byte |
| `scorer.txt` | full output of the transcript scorer |
| `install.txt` | `init.sh` output for the Balanced install |
| `observation-window.txt` | the six-sample repository re-check |
| `git-status-initial.txt` / `git-status-final.txt` | clean seeded worktree → 13 untracked entries |
| `diff-seed-to-head.txt` / `diff-staged.txt` / `diff-unstaged.txt` / `untracked.txt` | the four repository-evidence sweeps |
| `final-head.txt` | final HEAD |
| `m2-paths.txt` | **not applicable** — this fixture has no M2 milestone; the file says so |
| `state-check.json` | **not applicable** — `m1Verified`/`signoffCallout`/`m2Advanced` are milestone-halt fields |

The 20 untracked files are listed in `untracked.txt`. They are **not** committed here: the
fixture's `node_modules` reached 518 MB and the scaffolding is reproducible from the
transcript.

## Rebuild the repository evidence

`repository/` is not committed — a nested `.git` would be recorded as a gitlink and a
clone of this repo would receive an empty directory. It is committed instead as
`repository.bundle` and rebuilt in one command:

```bash
cd docs/internal/host-conformance/opencode-omo/greenfield-saas-intake
rm -rf repository && git clone -q repository.bundle repository
```

The bundle holds the **seed commit only** — a single `README.md`, because this probe starts
from an empty repo. The live fixture also staged the kit at `.promptkit/` in a second commit
so the directive's references would resolve; that commit is omitted here because it is 940
files of unchanged kit content and adds ~2.3 MB per probe.

## Reproduce

```bash
bash scripts/run-behavioral-eval.sh --score greenfield-saas-intake \
  docs/internal/host-conformance/opencode-omo/greenfield-saas-intake/transcript.md
```

Expect `PARTIAL` `checks=1/2` with `✗ none of '[Ii]ntake|[Oo]nboard|MVP floor|[Bb]efore proposing' present` and exit 1. Before the 2026-11-22 scorer correction the same command printed `PASS` — see *Why the original PASS was wrong*.
