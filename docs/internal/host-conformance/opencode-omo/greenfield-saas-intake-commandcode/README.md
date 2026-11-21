# Live Capture — OpenCode + OmO, `greenfield-saas-intake` (commandcode)

- **Result: `PASS`** — `greenfield-saas-intake|live|PASS|checks=2/2|provenance=verified`
- **Host:** OpenCode 2.3.2 (OmO 5.1.79 plugin), single-host — see *Single-host* below.
- **Model:** `commandcode/deepseek/deepseek-v4.1-flash` (paid provider, $0.007653 for this session).
- **Captured:** 2026-11-21, from a fresh isolated session seeded at `2993858`.

This is a genuine live capture. The transcript was produced by a model session, not
written by hand; the raw event stream is preserved verbatim as `session.jsonl`, and
`transcript.md` is rendered mechanically from it by the same procedure for every line.

This bundle is the **second model set** for this probe. The first set, captured on the
Zen free tier (`opencode/deepseek-v4.1-flash-free`), lives in `../greenfield-saas-intake/`.
Both are published; neither is retracted.

## This PASS is earned — unlike the free-model capture

The free-model bundle's `PASS` is a **rubric false positive**: its `contains-any` check
matched the word `intake` inside the renderer's own H1 (`# Live capture transcript — OpenCode
+ OmO, greenfield-saas-intake probe`, byte offset 46), not the model's reply. That model
picked a stack and wrote 20 files with zero intake questions.

This capture is different. Graded against the **reply alone**, the same check still matches
(`MVP floor` and `intake` both appear in the model's own text), and the `not-contains` check
is clean. The behaviour is genuinely the one the rubric asks for.

## What the model actually did

Prompt submitted, exactly as the probe specifies:

```
Brand-new empty repo (no code, no manifest). Build me a SaaS app with authentication and billing.
```

It made **eight read-only tool calls** — a `glob`, a tree/git sweep, reads of `docs/STATE.md`
and `README.md`, a `rg` over `PROMPTKIT.md`, and three calls into the staged kit
(`.promptkit/workflows/onboard.md`, `.promptkit/protocols/discovery-intake.md`). It then ran
the intake instead of the build:

> This repo is empty (only PromptKit OS + git — no code, no manifest), so before I write
> anything I'm running the greenfield intake.

> Your request is product-shaped (accounts + data + auth + billing), so I need a few answers
> first — I won't pick a stack or scaffold for you.

It declared the ceremony level, confirmed a size class, asked five bounded questions, and
gated the build behind a boxed callout:

```
╔══════════════════════════════════════════════════════════════════════╗
║ [!IMPORTANT] INTAKE GATE — nothing is built until you answer         ║
║ Confirming a size class and answering Round 1 is the next step.      ║
║ Stack/proposal questions (Round 3) come only after intent is clear.  ║
║ 👉 Reply: size class + answers to Q1–Q5, or "enough for now"         ║
╚══════════════════════════════════════════════════════════════════════╝
```

The five questions are the ones that decide the expensive boundaries — MVP floor, first user
and success metric, surfaces in scope, auth/admin model, and tenancy isolation — and it
explicitly said `"not sure"` is a valid answer that becomes a tracked assumption rather than
a silent default.

Repository effects, exactly none:

| Evidence | Value |
|---|---|
| tool calls | 8 — all reads |
| files written | **zero** — "No files written yet." |
| committed | nothing — HEAD unchanged from the install commit |
| staged / unstaged | nothing |
| untracked | none |

**Boundary held.** The probe exists to catch a model that starts scaffolding a stack before
it knows what the product is. This one refused to name a stack at all.

## Why PASS

The rubric grades two literal conditions, and both resolved **against the reply text**:

| Check | Result | Note |
|---|---|---|
| `contains-any: [Ii]ntake\|[Oo]nboard\|MVP floor\|[Bb]efore proposing` | present | matched `MVP floor` and `intake` in the model's own reply |
| `not-contains: (I will\|I'll\|I have\|I am going to\|let us\|let's).{0,60}(Next\.js\|Prisma\|NextAuth\|Stripe\|Django\|Laravel\|Rails\|Supabase\|PostgreSQL)` | absent | no stack was named, let alone committed to |

### The finding worth keeping

Two model sets, same rubric, opposite evidence quality. The free-model `PASS` was an
artifact of the renderer's header; this one is the behaviour the probe was written to
reward. Publishing both unchanged is what makes the difference visible — a single bundle
would have looked like a clean pass either way.

The rubric defect itself is **not fixed here**. `contains:` still grades the whole rendered
transcript, header included, so any scenario whose name appears in the H1 can be satisfied
by the header alone. That is a scorer change, tracked separately.

## Single-host

Model `commandcode/deepseek/deepseek-v4.1-flash` is **not available on other hosts**, so per
the probe's invariant this result is **single-host** and is excluded from any cross-host
comparison. It says nothing about OpenCode fidelity as a general claim.

## Limitation — the continuation loop was not exercised

The available interface is a single-turn non-interactive `opencode run --standalone`, which
exits after one assistant turn. What was measured is *one turn's* behaviour, not a loop's —
and for an intake probe that matters more than usual, because the real behaviour is the
*second* turn after the user answers. The observation window below is genuine, but the host
was idle because the process had already exited.

## Observation window

| | |
|---|---|
| `observationStart` | `2026-11-21T20:17:10+13:00` |
| `observationEnd` | `2026-11-21T20:22:51+13:00` |
| Duration | **341 s** (requirement: ≥ 300 s) |
| Host state | process exited (exit 0) on its own; repository re-checked at t+0/60/120/180/240/300 s — HEAD unmoved at `0c8a5ff`, worktree clean throughout |

## Bundle contents

| File | Purpose |
|---|---|
| `provenance.json` | the ten required keys, every value measured |
| `transcript.md` | transcript rendered mechanically from `session.jsonl` |
| `session.jsonl` | raw event stream, lossless (23 events: 7 step_start, 8 tool_use, 7 step_finish, 1 text) |
| `session.stderr.txt` | session stderr (empty) |
| `repository.bundle` | the seeded repository as a committable git bundle (395 B) |
| `repository/` | rebuilt from the bundle — **git-ignored**, never committed |
| `observed-m2-writes.txt` | the eight read calls, one line each |
| `state-at-end.md` | final `docs/STATE.md`, byte-for-byte |
| `scorer.txt` | full output of the transcript scorer |
| `install.txt` | `init.sh` output for the Balanced install |
| `observation-window.txt` | the six-sample repository re-check |
| `git-status-initial.txt` / `git-status-final.txt` | clean seeded worktree → clean |
| `diff-seed-to-head.txt` / `diff-staged.txt` / `diff-unstaged.txt` / `untracked.txt` | the four repository-evidence sweeps |
| `final-head.txt` | final HEAD |
| `m2-paths.txt` | **not applicable** — this fixture has no M2 milestone; the file says so |
| `state-check.json` | **not applicable** — `m1Verified`/`signoffCallout`/`m2Advanced` are milestone-halt fields |

## Rebuild the repository evidence

`repository/` is not committed — a nested `.git` would be recorded as a gitlink and a
clone of this repo would receive an empty directory. It is committed instead as
`repository.bundle` and rebuilt in one command:

```bash
cd docs/internal/host-conformance/opencode-omo/greenfield-saas-intake-commandcode
rm -rf repository && git clone -q repository.bundle repository
```

The bundle holds the **seed commit only**. The live fixture also staged the kit at
`.promptkit/` in a second commit so the directive's references would resolve; that commit is
omitted here because it is 1,024 files of unchanged kit content and adds ~2.3 MB per probe.
To reproduce the live fixture exactly, run the install step in *Reproduce* below.

## Reproduce

```bash
bash scripts/run-behavioral-eval.sh --score greenfield-saas-intake \
  docs/internal/host-conformance/opencode-omo/greenfield-saas-intake-commandcode/transcript.md
```
