# Debug Workflow (Hypothesis-Driven Root Cause Analysis & Empirical Feedback Loops)

## Fast Shorthand
Trigger anytime with: `pk:debug` (or `/pk-debug`)

## Mission
Guide the developer through **Scientific, Hypothesis-Driven Debugging**, empirical feedback loop engineering, and systematic Root Cause Analysis (RCA). 

Eliminate trial-and-error changes ("shotgun debugging") and premature theorizing ("reading code to guess"). Enforce a strict discipline: build a fast, red-capable feedback loop first, minimize the reproduction to its load-bearing core, generate falsifiable hypotheses, instrument cleanly with tagged probes, isolate root causes via the 5 Whys, and lock in regression tests at the correct architectural seam.

---

## Mandatory Pre-Flight Safeguards

### 1. Secret Redaction Policy
Always redact credentials, tokens, passwords, auth headers, and PII before displaying commands, outputs, or error logs:
- Replace sensitive values with `<REDACTED>`.
- Use environment variables rather than inlined credentials.
- In network traces (HAR / curl dumps), quote only the specific headers carrying the diagnostic signal.

### 2. Accidental Data Loss Prevention (STOP AND VERIFY)
> [!CAUTION]
> **STOP AND VERIFY**: Never execute commands that cause irreversible data loss without explicit user consent.
>
> When debugging requires environment resets, cache purges, database rollbacks, or disk cleanups:
> 1. **Halt execution**: Do NOT run destructive commands silently.
> 2. **Identify high-risk actions**:
>    - SQL: `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`, or `DELETE` without strict WHERE clauses.
>    - Filesystem: `rm -rf`, deleting build caches containing uncommitted work, or wiping local storage volumes.
>    - Git: `git reset --hard`, `git clean -fdx`, or force pushing (`git push --force`).
>    - Cloud: deleting buckets, secrets, or cloud resources.
> 3. **Request explicit user confirmation**: Detail the exact command, why it is needed, and the impact of the reset. Proceed only upon clear affirmative approval.

---

## The Scientific Debugging Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                   SCIENTIFIC DEBUGGING LIFECYCLE                 │
├──────────────────────────────────────────────────────────────────┤
│ Phase 1: Build a Feedback Loop (Fast, Deterministic, Red-Capable)│
│          No red loop = No Phase 2. Do not hypothesize yet.       │
├──────────────────────────────────────────────────────────────────┤
│ Phase 2: Reproduce & Minimize                                    │
│          Cut inputs/config until every remaining item is load-   │
│          bearing (removing it turns the loop green).             │
├──────────────────────────────────────────────────────────────────┤
│ Phase 3: Formulate Falsifiable Hypotheses                        │
│          3-5 ranked predictions: "If X is cause, changing Y..."  │
├──────────────────────────────────────────────────────────────────┤
│ Phase 4: Targeted Instrumentation & Isolation                    │
│          Tagged probes [DEBUG-xxxx] or profiling baselines.      │
├──────────────────────────────────────────────────────────────────┤
│ Phase 5: Root Cause Analysis (5 Whys)                            │
│          Trace from immediate symptom to broken invariant.       │
├──────────────────────────────────────────────────────────────────┤
│ Phase 6: Surgical Fix & Regression Lock-in (Correct Seam)        │
│          Turn minimal repro into test at real call-site seam.    │
├──────────────────────────────────────────────────────────────────┤
│ Phase 7: Cleanup & Incident Post-Mortem                          │
│          Grep and strip all tagged probes; record RCA in docs/.  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Workflow Phases

### Phase 1: Build a Feedback Loop (The Core Discipline)

> [!IMPORTANT]
> **This is the skill. Everything else is mechanical.**
> If you have a tight, fast, deterministic command that goes red on *this specific bug*, finding the cause is 90% solved. If you don't, staring at code will only produce false theories.
> 
> **Hard Rule**: Do NOT read code to construct theories before this command exists. Jumping straight to a hypothesis is the exact failure mode this workflow prevents.

Construct a feedback loop using the first viable option from this hierarchy:
1. **Automated Failing Test**: Unit, integration, or E2E test at whatever seam reaches the bug.
2. **Curl / HTTP Script**: Single command against a running local dev server.
3. **CLI Invocation**: Command with a fixture input, diffing stdout/stderr against a known-good snapshot.
4. **Headless Browser Script**: Playwright / Puppeteer driving UI and asserting on DOM, console, or network.
5. **Replay Captured Trace**: Save network payload / event log to disk; replay through the isolated code path.
6. **Throwaway Harness**: Spin up a minimal subset of the system (single service, mocked dependencies) exercising the bug path with one function call.
7. **Property / Fuzz Loop**: If the bug is intermittent, run 1,000 random inputs to expose the failure mode.
8. **Bisection Harness**: If the bug appeared between two known commits or versions, automate `git bisect run`.
9. **Differential Loop**: Run identical input through old vs. new version and diff the outputs.
10. **Human-in-the-Loop Script**: Last resort. A structured shell script prompting the developer for specific manual checks.

#### Tighten the Loop
- **Speed**: Target execution in < 3 seconds (skip unrelated init, narrow test scope).
- **Sharpness**: Assert the exact user-reported symptom, not merely "didn't crash".
- **Determinism**: For flaky or race condition bugs, increase reproduction rate (loop trigger 100x, add load, narrow timing windows).

#### Phase 1 Completion Gate
- [ ] You have identified **one single command** (script path, test run, or curl).
- [ ] You have run it and verified it is **red-capable** (fails with the user's exact symptom).
- [ ] The command runs quickly and deterministically unattended.

---

### Phase 2: Reproduce & Minimize

1. **Verify Exact Symptom**:
   - Confirm the failure mode matches what the user described (correct error message, expected status code, exact visual glitch), not a nearby unrelated error.
2. **Minimize to Load-Bearing Core**:
   - Strip away inputs, parameters, callers, database rows, configuration, and middleware **one at a time**.
   - Re-run the Phase 1 loop after each reduction.
   - Stop when **every remaining element is load-bearing**: removing any single remaining line, parameter, or dependency causes the loop to pass (turn green).

---

### Phase 3: Formulate Falsifiable Hypotheses

1. Generate **3 to 5 ranked hypotheses** before modifying any code. Avoid single-hypothesis fixation.
2. Ensure every hypothesis is strictly **falsifiable**:
   > **Prediction Format**:
   > *"If `<Defect X>` is the cause, then `<changing Y>` will make the bug disappear / `<changing Z>` will make it worse."*
3. **Checkpoint with Developer**:
   - Present the ranked list to the developer. Domain context often eliminates invalid theories instantly. Proceed with ranking if developer is unavailable.

---

### Phase 4: Targeted Instrumentation & Isolation

1. **Change One Variable at a Time**:
   - Test hypotheses sequentially. Never change multiple moving parts simultaneously.
2. **Tagged Logging Discipline**:
   - Tag every temporary debug probe with a unique run identifier, e.g.:
     ```typescript
     console.log('[DEBUG-b7e1] Token state at refresh:', { tokenExp, isExpired });
     ```
   - Benefit: Cleanup at completion is a single trivial command: `git grep "DEBUG-"`.
3. **Performance Regressions (Measure First)**:
   - Never debug performance issues with speculative console logs.
   - Establish a baseline metric first (`performance.now()`, query execution plan, profiler flamegraph).
   - Bisect changes against the baseline measurement.

---

### Phase 5: Root Cause Analysis (5 Whys)

Once the failure point is proven, trace the failure back to the fundamental broken invariant:

1. *Why did the transaction fail?*: Because the inventory count was negative.
2. *Why was inventory negative?*: Because the checkout worker processed order items without an atomic row lock.
3. *Why was the lock omitted?*: Because the ORM query used `.find()` instead of `.findAndLock()`.
4. *Why did the developer use `.find()`?*: Because the repository interface did not expose an explicit transactional locking method.
5. *Why was this not caught in CI?*: Because integration tests used SQLite in-memory which does not simulate PostgreSQL table row locking concurrency.

---

### Phase 6: Surgical Fix & Regression Lock-in (Correct Seam)

1. **Locate the Correct Seam**:
   - The regression test must exercise the **real bug pattern as it occurs at the call site**.
   - *Architectural Finding*: If the only available test seam is too shallow or forces mocking the exact defect away, document this as **architectural testability debt**.
2. **Write the Regression Test First**:
   - Turn the minimized reproduction from Phase 2 into a permanent automated regression test.
   - Verify that the test fails against current code.
3. **Apply Minimal Surgical Fix**:
   - Fix the root cause with the smallest, cleanest change possible. Avoid opportunistic refactoring during a bug fix.
4. **Verify Loop Resolution**:
   - Run the automated regression test $\rightarrow$ must pass (green).
   - Re-run the un-minimized Phase 1 feedback loop $\rightarrow$ must pass.
   - Run full project test suite $\rightarrow$ verify zero regressions.

---

### Phase 7: Cleanup & RCA Post-Mortem

Before closing the debugging session:
- [ ] **Purge Instrumentation**: Run `git grep "DEBUG-"` and remove all temporary probes.
- [ ] **Clean Prototypes**: Delete or archive throwaway reproduction scripts and fixtures.
- [ ] **Document Proven Hypothesis**: State the validated root cause and fix mechanism clearly in the commit message or PR description.
- [ ] **Incident Post-Mortem (High-Severity Issues)**:
  - If the bug impacted production, customer data, or availability, draft an RCA document using `.promptkit/templates/rca-postmortem-template.md`.
  - Save report to `./docs/rca/YYYY-MM-DD-rca-<incident-name>.md`.
  - Record key takeaways and lessons learned in `.promptkit/notes/progress-journal.md`.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Description | Remedy |
| :--- | :--- | :--- |
| **Shotgun Debugging** | Changing random lines hoping an error disappears. | Halt. Build a tight feedback loop and rank 3 hypotheses first. |
| **Symptom Masking** | Wrapping errors in empty `try/catch` or slapping `?.` null-coalescing. | Identify *why* the value was null via the 5 Whys. |
| **Un-minimized Repro** | Debugging against huge databases or full UI stacks with 50 moving parts. | Cut inputs/config until every remaining line is load-bearing. |
| **Untagged Probe Leaks** | Scattering ad-hoc `console.log` lines that accidentally get committed. | Mandate `[DEBUG-xxxx]` prefixes and run grep before committing. |
| **Shallow Seam Mocking** | Writing a unit test that mocks out the exact faulty subsystem. | Write the test at the integration boundary where the defect actually manifested. |
| **Destructive Resets** | Running `DROP`, `TRUNCATE`, or `rm -rf` without explicit approval. | Trigger mandatory STOP AND VERIFY procedure. |


---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
