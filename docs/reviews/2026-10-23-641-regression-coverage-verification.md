# #641 regression coverage and deferred-finding reconciliation — verification report

Date: 2026-10-23 (Pacific/Auckland)
Branch: `fix/641-regression-coverage` (worktree `.worktrees/641-regression-coverage`)
Base: `65e22b12061aca0c2d75211f0a834970812246f4` (current remote `main`)
Commits: `975c03e` (fixture family and harnesses), `49f9689` (register-presence check and eighth case), then this report's commit
Related issues: #641, #645, #646; this follow-up

Everything below was observed in this worktree. Nothing was pushed, merged, or recorded against any issue.

## 1. What this change adds

Issue #641 Scenario 6 required fixtures that reproduce four inconsistency families. PR #645 shipped none of them; only the deterministic doctor record-path check existed. This change adds the missing coverage as a fixture family with paired Bash and PowerShell harnesses and wires both into CI.

```
scripts/tests/fixtures/onboarding-provenance/
  README.md
  expected/cases.tsv
  cases/<case>/expected-output/docs/specs/2026-10-21-intake-acme-platform.md
  cases/<case>/expected-output/docs/STATE.md
scripts/tests/run-onboarding-provenance-fixtures.sh
scripts/tests/run-onboarding-provenance-fixtures.ps1
```

Each case is a complete artifact set: the Intake Record with machine-readable registers (Intake metadata, Decisions, Accepted defaults, Assumption records, Verification obligations, Round log) plus the generated `docs/STATE.md` those registers point at, so an obligation destination can be *resolved* rather than asserted. One shared TAB manifest pins, per case, the expected exit code, the exact summary line, and the complete normalized diagnostic set. Diagnostics are compared as a set, not a sample.

Registers are markdown tables on purpose: both twins parse them with the same rules and no prose heuristics, and a record that drops a register (or writes registers as prose) is rejected instead of silently yielding zero rows.

## 2. Case matrix as observed

| Case | Defect reproduced | Expected diagnostic | Observed exit |
| :--- | :--- | :--- | :--- |
| `valid-baseline` | none (positive control) | — | 0 |
| `assumption-still-open` | linked decision is `confirmed` while the assumption is still recorded `open` | `ASSUMPTION_STILL_OPEN` | 1 |
| `residual-risk-untracked` | assumption resolved but its residual risk has no destination | `RESIDUAL_RISK_UNTRACKED` | 1 |
| `default-widened` | accepted default claimed to settle an adjacent test-runner decision the human did not approve | `DEFAULT_WIDENED` | 1 |
| `count-contradiction` | `Rounds used` says 2 while three round rows exist | `COUNT_CONTRADICTION\|rounds\|stated=2\|recorded=3` | 1 |
| `question-budget-exceeded` | 9 questions asked for a `medium` intake (ceiling 8) | `QUESTION_BUDGET_EXCEEDED\|size=medium\|ceiling=8\|asked=9` | 1 |
| `obligation-untracked` | obligation with no owner, plus a second obligation whose destination section does not exist | `OBLIGATION_UNTRACKED\|...\|owner` and `OBLIGATION_DESTINATION_MISSING\|...\|docs/STATE.md §9` | 1 |
| `register-missing` | the Verification obligations register is absent | `REGISTER_MISSING\|Verification obligations` | 1 |

Observed matrix output (Bash, exit 0): `Onboarding provenance Bash matrix cases passed: 8 isolated contracts.`

## 3. Negative controls: before and after

Every non-baseline case is derived from `valid-baseline` by changing only the defective cells; `docs/STATE.md` is byte-identical to the baseline in all eight cases. Verified with a pairwise diff of each case against the baseline:

- `assumption-still-open`: one cell, Status `accepted by DECISION-acme-platform-001` → `open`.
- `residual-risk-untracked`: one cell, Destination `docs/STATE.md §5` → `-`.
- `default-widened`: two cells — DECISION-acme-platform-002 becomes "Vitest is the test runner for every platform package." and DEFAULT-acme-platform-001 `Resolves` becomes `none` (the adjacent list gains the test-runner decision).
- `count-contradiction`: round 2 Questions `2` → `1` plus a third round row; metadata still says 2.
- `question-budget-exceeded`: `Questions asked` `5` → `9` with round rows changed to 5 and 4, so the arithmetic still reconciles and only the budget rule can fire.
- `obligation-untracked`: Owner → `-` on the first obligation, plus a second obligation whose destination `docs/STATE.md §9` does not exist.
- `register-missing`: the whole Verification obligations section removed.

Before/after result: the baseline artifact passes (`VALID|DECISIONS=4|DEFAULTS=1|ASSUMPTIONS=2|OBLIGATIONS=1|ROUNDS=2`, exit 0); each mutated artifact is rejected with exactly the diagnostic listed in section 2 and no others. The harness also fails if a case manifest's stated `ERRORS` count disagrees with its listed diagnostics, so a manifest cannot quietly drift from the contract.

Harness integrity: per case, both twins snapshot every repository file hash and `git status --porcelain=v1 --untracked-files=all` before and after validation and fail if anything changed. The suite therefore proves it is read-only.

## 4. Rules covered here versus rules owned elsewhere

| Contract rule | Owner after this change |
| :--- | :--- |
| 3 bounded defaults, 4 assumption lifecycle, 5 residual risk, 6 obligations, 7 counts/budget, register presence | new fixture harnesses (both twins) |
| 1 no implied promotion, 2 traceable locks, 8 designated precedence | existing documentation-contract assertions plus the eight-item human-review checklist |
| derived PromptKit baselines | existing behavioral-contract assertions |
| invariant→decision references in `docs/STATE.md` | existing documentation-contract assertions plus manual review; not checked by this harness |
| whether a destination section's *content* supports the obligation | human review; this harness resolves only that the destination exists |

This boundary is stated in the fixture README and in both harness closing lines.

## 5. Cross-platform evidence

Environment: WSL2, Ubuntu 24.04.5 LTS, Linux 6.18.54.1-microsoft-standard-WSL2, bash 5.2.21, git 2.43.0, Python 3.12.3; `/home/heyloey/.local/bin/pwsh` is PowerShell 7.6.7 running on Microsoft Windows 10.0.26300.

| Path | Result | Status |
| :--- | :--- | :--- |
| Bash harness on Linux (worktree) | 8/8 cases, exit 0 | verified locally |
| PowerShell harness on Windows pwsh, Windows-local copy | 8/8 cases, exit 0 | verified locally |
| PowerShell harness over the `\\wsl.localhost\` UNC path | `HARNESS_FAILURE\|Unable to read Git status` | environment-limited, not a harness defect |
| Native Windows CI (`windows-latest`) | not run | pending push; authoritative when it runs |

Two WSL-interop facts, neither worked around in the committed script: Windows pwsh refuses the unsigned `.ps1` over UNC without `-ExecutionPolicy Bypass` (GitHub runners invoke `pwsh -NoProfile -File` and need no such flag), and `git status` over that UNC path fails with "detected dubious ownership in repository" and "`.git` may refer to a non-local directory". The committed harness deliberately contains no `safe.directory` mutation; real Windows CI uses a local path.

Parity was therefore established on a genuinely Windows-local copy (`/mnt/c/Users/jonel/AppData/Local/Temp/pk-prov-parity3-*`, a fresh timestamped directory, not deleted): harness pair plus fixture family copied there, `git init` + commit, then the Bash twin from WSL and the PowerShell twin via `wslpath -w`. Both runs exit 0 and produce the same eight case rows: identical case names, exit codes, diagnostics and summary lines, including the two-obligation case (`FAILED\|ERRORS=2\|...\|OBLIGATIONS=2\|ROUNDS=2`).

Residual byte-level difference, measured: with stdout redirected, Bash writes the section sign as UTF-8 `c2 a7`, Windows pwsh writes it in the OEM code page as the single byte `f5` and uses CRLF. This affects only log bytes; every assertion compares strings inside each twin, and both twins read the fixture artifacts as UTF-8, so no diagnostic differs. No other character in the matrix is non-ASCII.

CI wiring (not yet exercised): `bash -n` line in the Linux syntax cascade, a Bash run step after the onboarding-divergence Bash step, `scripts/tests/run-onboarding-provenance-fixtures.ps1` appended to the Windows `$syntaxFiles` parse list, and a PowerShell run step after the divergence PowerShell step in `windows-validate-core`.

## 6. Gate results (exact commands, this worktree)

| Command | Exit | Result line |
| :--- | :--- | :--- |
| `bash scripts/tests/run-onboarding-provenance-fixtures.sh` | 0 | `Onboarding provenance Bash matrix cases passed: 8 isolated contracts.` |
| `bash scripts/tests/run-behavioral-contract-tests.sh` | 0 | `Passed: 557 \| Failed: 0` |
| `bash scripts/tests/run-doctor-tests.sh` | 0 | `Passed: 42 \| Failed: 0 \| Skipped: 0` |
| `bash scripts/tests/run-onboard-divergence-fixtures.sh` | 0 | `4 isolated contracts.` |
| `bash scripts/tests/run-reference-link-tests.sh` | 0 | `Passed: 8 \| Failed: 0` |
| `bash scripts/validate-references.sh .` | 0 | `All references valid! No broken links found.` |
| `bash scripts/check-changelog-entry.sh` | 0 | `CHANGELOG_GATE\|PASS\|no behavior-surface paths in range, entry not required` |
| `bash scripts/measure-tokens.sh --strict` | 0 | `BALANCED\|2341\|2500\|PASS`, `LITE\|1456\|1500\|PASS` |
| `bash scripts/measure-per-task-tokens.sh --strict` | 0 | `Per-task baseline gate passed for all profiles.` |
| `bash scripts/measure-turbo-overhead.sh --strict` | 0 | `Turbo overhead claim within documented window.` |
| `bash scripts/validate-execution-control.sh --root .` | 0 | `VALID\|RECORDS=66\|ROOT=.` |
| `bash -n scripts/tests/run-onboarding-provenance-fixtures.sh` | 0 | no output |

Notes: `validate-references.sh` takes the engine root as its first argument and defaults to `.promptkit`, which does not exist in a worktree; the CI form is `bash scripts/validate-references.sh .`. The changelog gate does not require an entry here because behavior-surface matching covers `scripts/<file>` but not `scripts/tests/**`; the entry is voluntary and follows the #644 precedent. Token figures are unchanged from `main` because no measured input was touched.

## 7. F8, F9, F10 dispositions

**F8 — resolved.** `workflows/doctor.md` described four checks while the implementation emitted five. Tracked as #646, fixed by PR #649 (merge `0598f3635`), which documented `hosts`, `version`, `ignore-state`, `docs-drift` and intake `provenance`, and reproduced on current `main` as "Phase 2: The Five Checks".

**F9 and F10 — no recoverable definition; owner decision: rescinded.** Searches of the tracked tree, the retained review evidence, git history and unreachable objects, all refs, GitHub code/issue/PR search and agent session stores found no definition attached to #641. The only F9/F10-shaped tokens in the tracked tree belong to an unrelated installer review family: `docs/reviews/2026-10-01-merged-main-audit.md` line 96 ("F10 — [P2] Bash updates lose restrictive permissions on macOS/BSD tools"), `init.sh` line 998 and `scripts/tests/run-init-safety-tests.sh` line 470, all concerning init-file permissions rather than onboarding. Issue #646's out-of-scope line ("Implementing deferred F9 or F10 work in the same patch") proves they once existed but supplies no scope, owner, or acceptance criteria.

Owner decision, recorded here on 2026-10-23 at the maintainer's direction: **F9 and F10 are rescinded as undefined deferrals.** They carry no scope, no owner, no acceptance criteria and no owed work; future contributors must not treat them as tracked findings, and no unrelated finding may be relabelled as F9 or F10. This decision does not edit PR #645, issue #641, or any artifact retroactively; it records the disposition of the "F8–F10" sentence in #645, which is accurate only for F8.

## 8. #641 implementation-task reconciliation

| # | Task as written | Merged change | Evidence | Status |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Review the onboarding, discovery-intake, context-sync, checkpoint, project-profile, design-profile and state-tracker contracts; identify the narrowest canonical owner per rule | #645 (11 files) then #642, #643, #644, #646, #647, #648 | Each follow-up narrows exactly one owner: pre-write artifact (#642), profile label (#643), host-documentation divergence (#644), doctor five checks (#646), intake-record path authority (#647), §4 illustrative syntax (#648) | Satisfied, indirectly evidenced: no single owner-map document exists; the owner split is exhibited by the follow-up series |
| 2 | Decide which findings are deterministic and which need a human checklist | #645 | `protocols/discovery-intake.md` §G "Artifact Provenance Contract" (eight rules, line 247 onward) plus the eight-item Human-review checklist ending at line 284; `scripts/check-doctor.sh` check 5 is the deterministic part | Satisfied |
| 3 | Add regression fixtures using the existing cross-platform conventions | none on `main` | `main` has no fixture for these families; this branch adds the family, eight cases, two harnesses, CI wiring | **Not satisfied on `main`; completed on this branch, pending CI** |
| 4 | Update only the owning workflow/protocol/template/validator surfaces | #645 | Diff touches `protocols/discovery-intake.md`, two templates, two doctor scripts, tests, docs and changelog; no unrelated surface | Satisfied |
| 5 | Verify stale-assumption transitions, exact-scope defaults, decision references, metadata counts and obligation ownership | #645 assertions; this branch fixtures | On `main`: static assertions plus the manual checklist only. On this branch: eight executable cases covering transition, scope, counts and ownership; decision references remain with the documentation assertions | **Partially satisfied on `main`; the executable part completes on this branch** |
| 6 | Run reference, behavioral-contract and strict token-budget checks on supported platform paths | #645 plus merges | PR body figures reproduce on merge run 39561444224 (Linux behavioral 498/0, Linux doctor 42/0/0, Windows doc-contract 486/0 + 1 skip, Windows doctor 41/0/1); current `main` run 39753414434 shows 557/0, 42/0/0, 545/0 + 1 skip, 41/0/1 | Satisfied, verified from CI logs rather than the PR body |
| 7 | Document the enforcement boundary | #645 | `workflows/doctor.md` line 72 "What the provenance row does not prove"; discovery-intake checklist closing line; PR body statement that static checks establish artifact contracts, not universal live-agent behavior | Satisfied |

Smallest transparent correction: post one comment on #641 carrying this table, check tasks 1, 2, 4, 6 and 7 immediately (each has merge-visible evidence), and check tasks 3 and 5 only when this branch merges — on current `main` they are genuinely unmet, and checking them now would assert evidence that does not exist there. Do not close #641 as part of this work.

## 9. This follow-up's acceptance criteria

| Criterion | Result |
| :--- | :--- |
| Stale-assumption fixture: confirmed decision with an incorrectly active linked assumption | Met — `assumption-still-open`, plus `residual-risk-untracked` for the risk side |
| Default-widening fixture: accepted default expanded beyond approved scope | Met — `default-widened` |
| Metadata/obligation fixture: contradictory counts or inadequately tracked obligation | Met — `count-contradiction`, `question-budget-exceeded`, `obligation-untracked` |
| Each fixture has a meaningful expected verdict and, where applicable, a negative control | Met — every case pins the exact exit, summary and complete diagnostic set; seven genuine negative controls with a shared positive control |
| Bash and PowerShell provide equivalent coverage on supported platforms | Met locally on a Windows-local copy (identical eight case rows); native Windows CI run still pending |
| Authority boundaries and category distinctions intact | Met — no protocol, template, workflow, doctor, or schema change; fixture-only |
| F9/F10 evidence-backed definitions or an explicit owner decision | Met by owner decision: both rescinded (section 7) |
| All seven #641 tasks reconciled | Met — section 8 |
| CI and repository gates pass, skips reported accurately | Met for the local gate set (section 6); CI wiring unexercised until push, and the Windows runner remains authoritative |
| Documentation does not claim static tests prove live-model compliance | Met — fixture README, both harness closing lines, CHANGELOG entry and this report all state the boundary |

## 10. Residual risks and limitations

- **CI wiring is unverified until pushed.** The YAML edits parse and the steps mirror existing ones, but only a real run proves the Windows runner executes the new PowerShell step.
- **Local PowerShell evidence is environment-limited.** The UNC run cannot report parity; the Windows-local copy can, and its repository-integrity check exercises a genuinely local `git` repository rather than the CI checkout. Native Windows CI is still the authoritative check.
- **Log encoding differs between twins** (measured in section 5). It cannot change a verdict because comparisons happen in string space, but any future consumer that parses redirected PowerShell output as UTF-8 will mis-read the section sign.
- **Register parsing requires markdown tables.** A record that writes registers as prose is rejected as `REGISTER_MISSING`, which is the correct verdict but means this harness cannot validate a prose-only intake format.
- **Coverage is bounded to artifact shape.** The harness does not verify that an invariant in `docs/STATE.md` cites a real `DECISION-*` id, that a destination's content satisfies its obligation, that an accepted default's prose scope matches its declared scope, or that a human actually approved a decision. Those stay with the documentation-contract assertions and the bounded manual review.
- **A green matrix is not agent compliance.** Eight artifact shapes are classified as specified; nothing here shows that a live model produces consistent artifacts.

## 11. What this does not prove

It does not show that a running onboarding session preserves decision provenance, that every on-host mismatch is detected, or that any model follows the workflow. It proves that these eight generated artifact shapes are accepted or rejected exactly as the contract specifies, on both twins, and that the harness leaves the repository untouched.
