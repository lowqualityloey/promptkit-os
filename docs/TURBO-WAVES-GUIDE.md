# Turbo Waves Guide: Unattended Parallel Execution with `pk:auto`

How to run PromptKit OS autonomous pipelines — sequential or parallel — **without staying online**, and what the system will and will not do while you are away.

> This guide teaches and points. The normative rules live in `workflows/auto.md` and the referenced recipes; if anything here ever disagrees with those, the workflows win.

---

## 1. What Turbo Waves Are (and Are Not)

- **Are:** parallel lanes of the same `pk:auto` pipeline (plan → tasks → code → test → review), each lane in a fresh worker context, checkpointed per wave to `docs/STATE.md`.
- **Are not:** a scheduler, daemon, background service, or second orchestration engine. PromptKit defines governance; your host executes; you authorize.
- **Will never do:** merge, tag, publish, deploy, rollback, expand scope silently, or weaken tests to go green — in any profile, including Turbo.

---

## 2. Requirements

- **Turbo profile with explicit acknowledgement:** run `pk:profile --turbo --experimental` (or install with `--turbo --experimental`). Without acknowledgement Turbo refuses — Balanced/Lite behavior is unchanged.
- **A host that runs lanes concurrently.** Unsupported hosts fall back to sequential execution with identical correctness (and no wall-clock benefit).
- **Worthwhile task size.** Measured finding: on trivial tasks, coordination overhead loses to sequential work. Fan out only when each lane's work clearly exceeds dispatch + synthesis cost.

---

## 3. Walkthrough: Your First Unattended Run

1. **Certify the wave.** Open `docs/recipes/auto-waves-preflight-checklist.md` and tick every box: independent contracts, disjoint file ownership, no shared migration/artifact/schema, no inter-worker dependencies, host capability, task size.
2. **Declare the stop point.** Either plain words ("handle this end-to-end, stop at review") or an explicit flag (see §4).
3. **Invoke.** Example: `pk:auto --waves 2 --until review`.
4. **Read the Turn-1 banner.** It states the mode, stop boundary, and circuit breaker — that is your contract for the run.
5. **Walk away.** Phase-boundary checkpoints persist to `docs/STATE.md`; Ctrl+C / Stop reclaims control anytime with zero loss.
6. **Return to one of two outcomes:** a review-ready diff (or draft PR), or a halt report with reason, evidence, and resume action.

---

## 4. Commands and Stop Points

| Command | Stops at | Then you… |
|---|---|---|
| `pk:auto` (or "handle this end-to-end") | `review ready` — before any commit | Review the diff |
| `pk:auto --until task` | One active subtask verified green | Review, continue |
| `pk:auto --until test` | Tests green, before review audits | Decide on review |
| `pk:auto --until pr` | Draft PR opened (push authorized within this run only) | Review + merge yourself |
| `pk:auto --full` | All invocation-snapshot tasks done + PR | Review + merge yourself |
| `pk:auto --waves N` (max 4, Turbo only) | Same boundaries, lanes in parallel | Same as above, per wave |

Scope is frozen at invocation: newly discovered work needs a new run (new authorization).

---

## 5. Cost and Honesty Box

- **Token price:** up to ~2× total when fanned out (measured bound). Sequential runs cost the 1× baseline.
- **Wall-clock:** pays off only above the task-size threshold; below it, sequential wins (measured: 110s Turbo-2 vs 61s sequential on trivial work).
- **Evidence status:** single host, single model so far; token figures estimated by stated method. The project verdict (keep / refine / promote / remove) is pending real multi-host evidence — see the open Turbo strategy issue in the tracker.
- **Total tokens rise with parallelism** even as parent-thread attention is preserved (~250-token syntheses instead of ~19.5k raw dumps). You buy wall-clock and attention, not total tokens.

---

## 6. The Safety Model in Plain Words

- **Leash banner first:** every run announces what it will do and where it stops.
- **3-strike budget:** initial failure + at most 2 refines, then the worker parks with diagnostics. No fourth refinement, ever.
- **One park per wave:** a resumed wave that parks again halts the run — no recursive parking, no queues.
- **Worker GREEN ≠ Wave GREEN:** all-green lanes still face integrated-state verification before the wave succeeds.
- **Halt blocks are records, not triggers:** nothing polls them, nothing auto-resumes. You read, diagnose, and authorize the next run.
- **Test Immobility:** no one — worker, wave, or reviewer — edits tests to manufacture green.

---

## 7. FAQ

**Can I leave it for hours?**
Yes — that is the supported pattern. Expect either progress-to-boundary or a safely parked halt report when you return. It will not notify you; check back.

**Will it merge or release while I am away?**
No. Merge, tag, publish, deploy, and rollback are human-only with no exception in any profile.

**My tasks are tiny — should I use waves?**
No. Run sequential; waves add coordination overhead that small work cannot repay.

**My host runs lanes one at a time — is that broken?**
No. The run falls back to sequential automatically with identical correctness; only the wall-clock benefit disappears.

**A wave failed halfway — is progress lost?**
No. Wave-boundary checkpoints in `docs/STATE.md` make every boundary a resume point; `git restore` / `git revert` undo unintended files or commits.

**Where do I go deeper?**
Pre-flight ticks: `docs/recipes/auto-waves-preflight-checklist.md`. Phrase→boundary map: `docs/recipes/auto-phrase-boundary-sheet.md`. Pause/resume mechanics: `docs/recipes/auto-wave-pause-resume.md`. Normative rules: `workflows/auto.md`.

---

## Related References

- [`workflows/auto.md`](../workflows/auto.md) — normative pipeline, boundaries, wave rules
- [`protocols/subagent-delegation.md`](../protocols/subagent-delegation.md) — briefing contract and synthesis caps
- [`protocols/code-quality-gate.md`](../protocols/code-quality-gate.md) — Action Authority Model (single source)
- [`BENCHMARKS.md`](./BENCHMARKS.md) — token economics and Turbo bounds
