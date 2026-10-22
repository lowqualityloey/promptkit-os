# #641 regression coverage and deferred-finding reconciliation — verification report

Date: 2026-10-23 (Pacific/Auckland)
Branch: `fix/641-regression-coverage` (worktree `.worktrees/641-regression-coverage`)
Base: `65e22b12061aca0c2d75211f0a834970812246f4` (current remote `main`)
Commits: `975c03e` (fixture family and harnesses), `49f9689` (register-presence check and eighth case), `db1317b` (corrective pass for review findings F1–F7), `1397691` (canonical register headers and exact manifest field counting), `9e0b884` (decision-link syntax and row-width fail-closed, sixteen cases), then this report's own commit
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

Registers are markdown tables on purpose: both twins parse them with the same rules and no prose heuristics. A record that drops a register is rejected as `REGISTER_MISSING`; a record whose register is present but not the expected table is rejected as `REGISTER_NOT_TABULAR`, so an unreadable register cannot read as "nothing to report". Tabularity is checked against the complete ordered header row — every column name, in position — not just the first cell and the column count, and a malformed register suppresses the dependent semantic checks instead of fanning out.

Every parsed data row must carry exactly the declared cell count for its register
(Intake metadata 2, Decisions 4, Accepted defaults 6, Assumption records 8,
Verification obligations 5, Round log 3). A short or over-wide row is one
`ROW_WIDTH` diagnostic naming the register, the expected and actual counts, and
the row's leading identifying cell; the register is then treated as structurally
unclean and its dependent semantic checks are suppressed, so a row the checker
cannot read reliably never produces a cascade of confident follow-on findings.

An assumption's `Linked decision` cell may hold a placeholder (blank, `-`, or
`none`) meaning the absence of a link, in which case no lifecycle rule applies.
Any other value must match the `DECISION-<slug>-<nnn>` identifier syntax and must
name a decision present in the Decisions register: a malformed value is
`ASSUMPTION_LINK_INVALID`, a well-formed value with no matching row is
`ASSUMPTION_LINK_UNRESOLVED`, and neither replaces or duplicates a genuine
`ASSUMPTION_STILL_OPEN` verdict. Both harnesses also fail closed on a case directory that the manifest does not declare, a manifest row that is not exactly four tab-separated fields (trailing tab, repeated tab leaving an empty field, or a fifth field), an empty case name, or a stated expected exit code that is not numeric.

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
| `register-not-tabular` | the Verification obligations register is present as prose instead of the required table | `REGISTER_NOT_TABULAR\|Verification obligations` | 1 |
| `assumption-link-unresolved` | an assumption claims `DECISION-acme-platform-099`, which is not in the Decisions register | `ASSUMPTION_LINK_UNRESOLVED\|ASSUMPTION-acme-platform-002\|DECISION-acme-platform-099` | 1 |
| `header-renamed` | the Verification obligations header renames `Status` to `State` | `REGISTER_NOT_TABULAR\|Verification obligations` | 1 |
| `header-reordered` | the Decisions header swaps the `Status` and `Statement` columns | `REGISTER_NOT_TABULAR\|Decisions` | 1 |
| `assumption-link-malformed` | an assumption's `Linked decision` cell carries `DEC-acme-platform-099`, which is not identifier syntax | `ASSUMPTION_LINK_INVALID\|ASSUMPTION-acme-platform-002\|DEC-acme-platform-099` | 1 |
| `assumption-link-absent` | none (positive control): the same cell holds `-`, an intentional absence of a link | — | 0 |
| `row-width-decisions` | a Decisions row gains a fifth cell, so it no longer matches the declared four | `ROW_WIDTH\|Decisions\|expected=4\|actual=5\|row=DECISION-acme-platform-001` | 1 |
| `row-width-assumptions` | an Assumption records row loses its `Destination` cell, so it carries seven of eight | `ROW_WIDTH\|Assumption records\|expected=8\|actual=7\|row=ASSUMPTION-acme-platform-001` | 1 |

Observed matrix output (Bash, exit 0): `Onboarding provenance Bash matrix cases passed: 16 isolated contracts.` The PowerShell twin reports the same sixteen contracts (section 5).

## 3. Negative controls: before and after

Every non-baseline case is derived from `valid-baseline` by changing only the defective cells; `docs/STATE.md` is byte-identical to the baseline in all sixteen cases (`sha256 d12e416c517c0758442ce535635e7eeaad62524c1a43073e138d5aa6d422f2ae`). Verified with a pairwise diff of each case against the baseline:

- `assumption-still-open`: one cell, Status `accepted by DECISION-acme-platform-001` → `open`.
- `residual-risk-untracked`: one cell, Destination `docs/STATE.md §5` → `-`.
- `default-widened`: two cells — DECISION-acme-platform-002 becomes "Vitest is the test runner for every platform package." and DEFAULT-acme-platform-001 `Resolves` becomes `none` (the adjacent list gains the test-runner decision).
- `count-contradiction`: round 2 Questions `2` → `1` plus a third round row; metadata still says 2.
- `question-budget-exceeded`: `Questions asked` `5` → `9` with round rows changed to 5 and 4, so the arithmetic still reconciles and only the budget rule can fire.
- `obligation-untracked`: Owner → `-` on the first obligation, plus a second obligation whose destination `docs/STATE.md §9` does not exist.
- `register-missing`: the whole Verification obligations section removed.
- `register-not-tabular`: the Verification obligations table replaced by one prose sentence.
- `assumption-link-unresolved`: `DECISION-acme-platform-004` → `DECISION-acme-platform-099` in one cell.
- `header-renamed`: one header cell, `Status` → `State` in the Verification obligations header.
- `header-reordered`: the same four Decisions header names in the order `Decision ID | Statement | Status | Provenance`.
- `assumption-link-malformed`: one cell, `DECISION-acme-platform-004` → `DEC-acme-platform-099`, which is not identifier syntax.
- `assumption-link-absent`: one cell, the same link → `-`, an intentional absence of a link rather than a broken one; this case must pass, so it is a positive control for the link rule rather than another negative control.
- `row-width-decisions`: one row, a fifth `extra` cell appended to `DECISION-acme-platform-001`.
- `row-width-assumptions`: one row, `ASSUMPTION-acme-platform-001`'s `Destination` cell removed.

Before/after result: the baseline artifact passes (`VALID|DECISIONS=4|DEFAULTS=1|ASSUMPTIONS=2|OBLIGATIONS=1|ROUNDS=2`, exit 0); each mutated artifact is rejected with exactly the diagnostic listed in section 2 and no others. The harness also fails if a case manifest's stated `ERRORS` count disagrees with its listed diagnostics, so a manifest cannot quietly drift from the contract.

Harness integrity: per case, both twins snapshot every repository file hash and `git status --porcelain=v1 --untracked-files=all` before and after validation and fail if anything changed. The suite therefore proves it is read-only.

## 4. Rules covered here versus rules owned elsewhere

| Contract rule | Owner after this change |
| :--- | :--- |
| 3 bounded defaults, 4 assumption lifecycle (including decision-link resolution), 5 residual risk, 6 obligations, 7 counts/budget, register presence and tabularity | new fixture harnesses (both twins) |
| 1 no implied promotion, 2 traceable locks, 8 designated precedence | existing documentation-contract assertions plus the eight-item human-review checklist |
| derived PromptKit baselines | existing behavioral-contract assertions |
| invariant→decision references in `docs/STATE.md` | existing documentation-contract assertions plus manual review; not checked by this harness |
| whether a destination section's *content* supports the obligation | human review; this harness resolves only that the destination exists |

This boundary is stated in the fixture README and in both harness closing lines.

## 5. Cross-platform evidence

Environment: WSL2, Ubuntu 24.04.5 LTS, Linux 6.18.54.1-microsoft-standard-WSL2, bash 5.2.21, git 2.43.0, Python 3.12.3; `/home/heyloey/.local/bin/pwsh` is PowerShell 7.6.7 running on Microsoft Windows 10.0.26300.

| Path | Result | Status |
| :--- | :--- | :--- |
| Bash harness on Linux (worktree) | 16/16 cases, exit 0 | verified locally |
| PowerShell harness on Windows pwsh, Windows-local copy | 16/16 cases, exit 0 | verified locally |
| PowerShell harness over the `\\wsl.localhost\` UNC path | `HARNESS_FAILURE\|Unable to read Git status` | environment-limited, not a harness defect |
| Native Windows CI (`windows-latest`) | not run | pending push; authoritative when it runs |

Two WSL-interop facts, neither worked around in the committed script: Windows pwsh refuses the unsigned `.ps1` over UNC without `-ExecutionPolicy Bypass` (GitHub runners invoke `pwsh -NoProfile -File` and need no such flag), and `git status` over that UNC path fails with "detected dubious ownership in repository" and "`.git` may refer to a non-local directory". The committed harness deliberately contains no `safe.directory` mutation; real Windows CI uses a local path.

Parity was therefore established on genuinely Windows-local copies (`/mnt/c/Users/jonel/AppData/Local/Temp/pk-fix2-1792692948`, `pk-hard2-1792693740`, and for the final sixteen-case run `pk-parity-p-1792699341` with its Linux twin `/tmp/pk-parity-b-1792699341`; fresh timestamped directories, not deleted): harness pair plus fixture family copied there, `git init` + commit, then the Bash twin from WSL and the PowerShell twin via `wslpath -w`. The final run instrumented patched copies only, writing both row sets under `/tmp/parity-evidence-1792699341`: 16 rows each, `BASH_EXIT=0`, `PS_EXIT=0`, and after normalizing line endings and the section-sign byte the two row sets are byte-identical (`IDENTICAL`). Both runs exit 0 and produce the same sixteen case rows: identical case names, exit codes, diagnostics and summary lines, including the two-obligation case (`FAILED|ERRORS=2|...|OBLIGATIONS=2|ROUNDS=2`) and both new width cases (`ROW_WIDTH|Decisions|expected=4|actual=5|...` and `ROW_WIDTH|Assumption records|expected=8|actual=7|...`). Per-case instrumentation printed `CASE|<name>|<diagnostic>` rows from patched copies in the temporary directory; after sorting, the only differing line is the section sign byte described below. The unpatched committed twins pass unmodified, each closing with `matrix cases passed: 16 isolated contracts.`

Residual byte-level difference, measured: with stdout redirected, Bash writes the section sign as UTF-8 `c2 a7`, Windows pwsh writes it in the OEM code page as the single byte `f5` and uses CRLF. This affects only log bytes; every assertion compares strings inside each twin, and both twins read the fixture artifacts as UTF-8, so no diagnostic differs. No other character in the matrix is non-ASCII.

CI wiring (not yet exercised): `bash -n` line in the Linux syntax cascade, a Bash run step after the onboarding-divergence Bash step, `scripts/tests/run-onboarding-provenance-fixtures.ps1` appended to the Windows `$syntaxFiles` parse list, and a PowerShell run step after the divergence PowerShell step in `windows-validate-core`.

## 6. Gate results (exact commands, this worktree, HEAD `9e0b884`)

| Command | Exit | Result line |
| :--- | :--- | :--- |
| `bash scripts/tests/run-onboarding-provenance-fixtures.sh` | 0 | `Onboarding provenance Bash matrix cases passed: 16 isolated contracts.` |
| `bash scripts/tests/run-behavioral-contract-tests.sh` | 0 | `Passed: 557 \| Failed: 0` |
| `bash scripts/tests/run-doctor-tests.sh` | 0 | `Passed: 42 \| Failed: 0 \| Skipped: 0` |
| `bash scripts/tests/run-onboard-divergence-fixtures.sh` | 0 | `4 isolated contracts.` |
| `bash scripts/tests/run-reference-link-tests.sh` | 0 | `Passed: 8 \| Failed: 0` |
| `bash scripts/validate-references.sh .` | 0 | `All references valid! No broken links found.` |
| `bash scripts/check-changelog-entry.sh --base 65e22b12061aca0c2d75211f0a834970812246f4` | 0 | `CHANGELOG_GATE\|PASS\|no behavior-surface paths in range, entry not required` |
| `bash scripts/measure-tokens.sh --strict` | 0 | `BALANCED\|2341\|2500\|PASS`, `LITE\|1456\|1500\|PASS` |
| `bash scripts/measure-per-task-tokens.sh --strict` | 0 | `Per-task baseline gate passed for all profiles.` |
| `bash scripts/measure-turbo-overhead.sh --strict` | 0 | `Turbo overhead claim within documented window.` |
| `bash scripts/validate-execution-control.sh --root .` | 0 | `VALID\|RECORDS=66\|ROOT=.` |
| `bash -n` on every touched shell script | 0 | no output |
| PowerShell `Parser::ParseFile` on the twin | 0 | `PARSE_ERRORS=0` |

Notes: `validate-references.sh` takes the engine root as its first argument and defaults to `.promptkit`, which does not exist in a worktree; the CI form is `bash scripts/validate-references.sh .`. `check-changelog-entry.sh` accepts `--base REF`; passing a bare positional ref is a usage error (exit 2) and is not a gate failure. The changelog gate does not require an entry here because behavior-surface matching covers `scripts/<file>` but not `scripts/tests/**`; the entry is voluntary and follows the #644 precedent. Token figures are unchanged from `main` because no measured input was touched. The battery above was run on the tree committed as `9e0b884` plus this report's own text, which is documentation only and which no gate consumes except reference validation; that gate was re-run after this report was finalised and stayed at exit 0.

## 7. F8, F9, F10 dispositions

**F8 — resolved.** `workflows/doctor.md` described four checks while the implementation emitted five. Tracked as #646, fixed by PR #649 (merge `0598f3635`), which documented `hosts`, `version`, `ignore-state`, `docs-drift` and intake `provenance`, and reproduced on current `main` as "Phase 2: The Five Checks".

**F9 and F10 — no recoverable definition; owner decision: rescinded.** Searches of the tracked tree, the retained review evidence, git history and unreachable objects, all refs, GitHub code/issue/PR search and agent session stores found no definition attached to #641. The only F9/F10-shaped tokens in the tracked tree belong to an unrelated installer review family: `docs/reviews/2026-10-01-merged-main-audit.md` line 96 ("F10 — [P2] Bash updates lose restrictive permissions on macOS/BSD tools"), `init.sh` line 998 and `scripts/tests/run-init-safety-tests.sh` line 470, all concerning init-file permissions rather than onboarding. Issue #646's out-of-scope line ("Implementing deferred F9 or F10 work in the same patch") proves they once existed but supplies no scope, owner, or acceptance criteria.

Owner decision, recorded here on 2026-10-23 at the maintainer's direction: **F9 and F10 are rescinded as undefined deferrals.** They carry no scope, no owner, no acceptance criteria and no owed work; future contributors must not treat them as tracked findings, and no unrelated finding may be relabelled as F9 or F10. This decision does not edit PR #645, issue #641, or any artifact retroactively; it records the disposition of the "F8–F10" sentence in #645, which is accurate only for F8.

## 8. #641 implementation-task reconciliation

| # | Task as written | Merged change | Evidence | Status |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Review the onboarding, discovery-intake, context-sync, checkpoint, project-profile, design-profile and state-tracker contracts; identify the narrowest canonical owner per rule | #645 (11 files) then #642, #643, #644, #646, #647, #648 | Each follow-up narrows exactly one owner: pre-write artifact (#642), profile label (#643), host-documentation divergence (#644), doctor five checks (#646), intake-record path authority (#647), §4 illustrative syntax (#648) | Satisfied, indirectly evidenced: no single owner-map document exists; the owner split is exhibited by the follow-up series |
| 2 | Decide which findings are deterministic and which need a human checklist | #645 | `protocols/discovery-intake.md` §G "Artifact Provenance Contract" (eight rules, line 247 onward) plus the eight-item Human-review checklist ending at line 284; `scripts/check-doctor.sh` check 5 is the deterministic part | Satisfied |
| 3 | Add regression fixtures using the existing cross-platform conventions | none on `main` | `main` has no fixture for these families; this branch adds the family, sixteen cases, two harnesses, CI wiring | **Not satisfied on `main`; completed on this branch, pending CI** |
| 4 | Update only the owning workflow/protocol/template/validator surfaces | #645 | Diff touches `protocols/discovery-intake.md`, two templates, two doctor scripts, tests, docs and changelog; no unrelated surface | Satisfied |
| 5 | Verify stale-assumption transitions, exact-scope defaults, decision references, metadata counts and obligation ownership | #645 assertions; this branch fixtures | On `main`: static assertions plus the manual checklist only. On this branch: ten executable cases covering transition, scope, decision-link resolution, counts and ownership | **Partially satisfied on `main`; the executable part completes on this branch** |
| 6 | Run reference, behavioral-contract and strict token-budget checks on supported platform paths | #645 plus merges | PR body figures reproduce on merge run 39561444224 (Linux behavioral 498/0, Linux doctor 42/0/0, Windows doc-contract 486/0 + 1 skip, Windows doctor 41/0/1); current `main` run 39753414434 shows 557/0, 42/0/0, 545/0 + 1 skip, 41/0/1 | Satisfied, verified from CI logs rather than the PR body |
| 7 | Document the enforcement boundary | #645 | `workflows/doctor.md` line 72 "What the provenance row does not prove"; discovery-intake checklist closing line; PR body statement that static checks establish artifact contracts, not universal live-agent behavior | Satisfied |

Smallest transparent correction: post one comment on #641 carrying this table, check tasks 1, 2, 4, 6 and 7 immediately (each has merge-visible evidence), and check tasks 3 and 5 only when this branch merges — on current `main` they are genuinely unmet, and checking them now would assert evidence that does not exist there. Do not close #641 as part of this work.

## 9. This follow-up's acceptance criteria

| Criterion | Result |
| :--- | :--- |
| Stale-assumption fixture: confirmed decision with an incorrectly active linked assumption | Met — `assumption-still-open`, plus `residual-risk-untracked` for the risk side and `assumption-link-unresolved` for a link that does not resolve |
| Default-widening fixture: accepted default expanded beyond approved scope | Met — `default-widened` |
| Metadata/obligation fixture: contradictory counts or inadequately tracked obligation | Met — `count-contradiction`, `question-budget-exceeded`, `obligation-untracked`, `register-missing`, `register-not-tabular` |
| Each fixture has a meaningful expected verdict and, where applicable, a negative control | Met — every case pins the exact exit, summary and complete diagnostic set; fourteen genuine negative controls with two positive controls (`valid-baseline` and `assumption-link-absent`) |
| Bash and PowerShell provide equivalent coverage on supported platforms | Met locally on Windows-local copies (identical sixteen case rows); native Windows CI run still pending |
| Authority boundaries and category distinctions intact | Met — no protocol, template, workflow, doctor, or schema change; fixture-only |
| F9/F10 evidence-backed definitions or an explicit owner decision | Met by owner decision: both rescinded (section 7) |
| All seven #641 tasks reconciled | Met — section 8 |
| CI and repository gates pass, skips reported accurately | Met for the local gate set (section 6); CI wiring unexercised until push, and the Windows runner remains authoritative |
| Documentation does not claim static tests prove live-model compliance | Met — fixture README, both harness closing lines, CHANGELOG entry and this report all state the boundary |

## 10. Corrective pass: pre-push review findings F1–F7

The pre-push review of commit `f5add69` found seven defects. Each is reproduced once against the pre-correction behavior and re-tested against `db1317b`. The two Medium findings blocked the branch: in both cases the harness reported a green matrix for an artifact the contract says must be rejected.

| # | Severity | Finding | Reproduction before the fix | Fix | Verification after the fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| F1 | Medium | Register presence keyed only to the `## heading`, so a register written as prose yielded zero rows and every rule over it passed silently | Replacing the Decisions table with prose produced no diagnostic; with manifest counts lowered the suite exited 0 | Each required register must carry its expected header row, separator row and column count; absent → `REGISTER_MISSING`, present-but-unparseable → `REGISTER_NOT_TABULAR`; link rules stay gated on a usable Decisions register so one defect does not fan out | Committed case `register-not-tabular` → `REGISTER_NOT_TABULAR|Verification obligations`, exit 1. Isolated `decisions-prose` reproduction (temporary copy): exactly one diagnostic `REGISTER_NOT_TABULAR|Decisions` plus `FAILED|ERRORS=1|DECISIONS=0|DEFAULTS=1|ASSUMPTIONS=2|OBLIGATIONS=1|ROUNDS=2`, 11 contracts pass, no `ASSUMPTION_*` cascade |
| F2 | Medium | A `Linked decision` that names a nonexistent decision silently disabled the lifecycle rule | `DECISION-...-099` with status `open` emitted no diagnostic and validated as `VALID` | Every link is resolved against the Decisions register; unresolved → `ASSUMPTION_LINK_UNRESOLVED|<assumption>|<decision>`, and an unresolved link replaces (never duplicates) the lifecycle verdict for that row | Committed case `assumption-link-unresolved` → single diagnostic, exit 1, counts unchanged |
| F3 | Low | PowerShell repository snapshot pruned every path starting `.git`, dropping `.gitignore`, `.gitattributes` and `.github` from the read-only proof | Predicate test showed `.gitignore` excluded | Skip only the `.git` entry itself, using the repo's existing relative-path convention | Filter predicate measured over the worktree: old filter excluded 5 entries, new filter excludes 1; `.gitignore skippedByNewFilter=False`, `.gitattributes skippedByNewFilter=False` |
| F4 | Low | A case directory missing from the manifest was silently ignored | Extra `cases/zzz-orphan/` left the suite green | Fail closed before the run if any case directory is undeclared | Bash: `HARNESS_FAILURE|Case directory not declared in expected/cases.tsv: zzz-orphan`, exit 1. PowerShell: identical message, exit 1 |
| F5 | Low | Inverted valid-branch message ("expects diagnostics with a failing exit") in both twins | — | Message corrected in both twins | `grep` shows `declares no diagnostics but a failing expected exit` in `run-...-fixtures.sh:274` and `run-...-fixtures.ps1:391` |
| F6 | Low | PowerShell dropped fields beyond the fourth on a malformed manifest row and threw a raw conversion exception on a non-numeric exit | — | Reject any row whose field count is not exactly four; parse the exit with `TryParse` and fail through `HARNESS_FAILURE` | PowerShell: five-field row → `HARNESS_FAILURE|Malformed manifest row for case extra-field: expected 4 tab-separated fields`, exit 1; `nope` → `... expected exit 'nope' is not numeric`, exit 1. Bash: same two messages, exit 1 |
| F7 | Low | Fixture README rule row said "4 registers present" while six are required | — | Row corrected to "registers present and tabular" listing six | `README.md:43` |

All three fail-closed reproductions (F4, F6) were executed against the unmodified committed twin on the Windows-local copy `pk-hard2-1792693740`; the F1 suppression reproduction used a temporary eleventh case in a throwaway copy under `/tmp`, never in the repository. Neither harness gained a self-test mode: the repository has no harness-of-harness convention, so the F1/F2 defects are guarded by committed cases and F4–F6 by the documented isolated reproductions above.

Both twins were re-run after the correction: Bash `12 isolated contracts`, PowerShell `12 isolated contracts`, exit 0, with the twelve case rows matching (section 5).

## 11. Second corrective pass: complete-header and field-count hardening (F1, F6)

A follow-up review of `db1317b` found that the F1 and F6 fixes stopped short of the property they claimed. Both are corrected in `1397691`.

| # | Finding after `db1317b` | Reproduction before the fix | Fix in `1397691` | Verification after the fix |
| :--- | :--- | :--- | :--- | :--- |
| F1 | Register structure was compared as first header cell plus column count, so a header that renamed or reordered a column still validated as tabular | Swapping `Status` and `Statement` in the Decisions header, or renaming `Status` to `State` in the Verification obligations header, produced no diagnostic | Capture the complete ordered header row in both twins and compare it cell by cell against the canonical row for each register; a mismatch is one `REGISTER_NOT_TABULAR|<register>` and the dependent semantic checks stay suppressed | Committed cases `header-reordered` → `REGISTER_NOT_TABULAR|Decisions` and `header-renamed` → `REGISTER_NOT_TABULAR|Verification obligations`, exit 1 each, counts unchanged |
| F6 | The Bash manifest reader relied on `IFS=$'\t' read`, which collapses repeated and trailing tabs, so an empty or trailing field could still reach the parser as four fields | A trailing tab, a repeated tab leaving an empty field, or a fifth field could be accepted as a four-field row depending on where the empty field fell | Count tabs on the raw row, require exactly four fields, and reject an empty case name | Bash: trailing tab, repeated tab, and fifth field each fail with `HARNESS_FAILURE|Malformed manifest row for case valid-baseline: expected 4 tab-separated fields`, exit 1; `nope` exit fails `... expected exit 'nope' is not numeric`, exit 1; empty name fails as an undeclared case directory, exit 1. PowerShell: identical messages for all five controls, exit 1 each |

All five malformed-manifest controls were exercised against throwaway copies (fresh `git init` per copy) so no repository file was mutated, and the PowerShell controls were re-measured without a pipe so the recorded exit code is the harness's own. The positive baseline and every earlier negative case are unchanged: both twins still report `12 isolated contracts`, exit 0, with matching rows (section 5). The PowerShell twin additionally parses with `PARSE_ERRORS=0`.

## 12. Third corrective pass: decision-link syntax and row-width fail-closed (S1, S2)

A further review of `693ee16` found two ways an artifact could still be accepted while the contract says it must be rejected. Both are corrected on this branch.

| # | Finding after `693ee16` | Reproduction before the fix | Fix | Verification after the fix |
| :--- | :--- | :--- | :--- | :--- |
| S1 | An assumption's `Linked decision` cell was only examined when it began with `DECISION-`; any other non-placeholder value was silently ignored, so a typo or a truncated id disabled the lifecycle rule instead of failing | `assumption-link-malformed` (link `DEC-acme-platform-099`) analysed by the pre-pass checker: **no diagnostic at all** and `COUNTS|DECISIONS=4|DEFAULTS=1|ASSUMPTIONS=2|OBLIGATIONS=1|ROUNDS=2`, i.e. the case would have passed as `VALID`, exit 0 | Define the placeholder set that means "no link" (blank, `-`, `none` — the set the checker already treats as absent), require every other value to match the `DECISION-<slug>-<nnn>` identifier syntax, and require the identified decision to exist. Malformed → `ASSUMPTION_LINK_INVALID|<assumption>|<value>`; well-formed but absent → `ASSUMPTION_LINK_UNRESOLVED|<assumption>|<decision>`. Resolution is gated on a usable Decisions register, so a malformed Decisions table cannot manufacture link verdicts | Committed case `assumption-link-malformed` → single diagnostic `ASSUMPTION_LINK_INVALID\|ASSUMPTION-acme-platform-002\|DEC-acme-platform-099`, exit 1; committed positive control `assumption-link-absent` (same cell → `-`) → `VALID`, exit 0; `assumption-still-open` still reports `ASSUMPTION_STILL_OPEN` unchanged |
| S2 | A parsed data row was read by field index without checking the row's cell count, so an over-wide row had its extra cells dropped and a short row was read with empty trailing cells; neither produced a diagnostic | `row-width-decisions` (fifth cell added) and `row-width-assumptions` (`Destination` removed) analysed by the pre-pass checker: **no diagnostic** in either case, with the malformed row still counted (`DECISIONS=4` and `ASSUMPTIONS=2`) | Require every parsed row to carry exactly the declared cell count per register (Intake metadata 2, Decisions 4, Accepted defaults 6, Assumption records 8, Verification obligations 5, Round log 3). One diagnostic convention: `ROW_WIDTH\|<register>\|expected=<n>\|actual=<n>\|row=<leading identifying cell>` (`none` when that cell is empty). A width defect marks the register structurally unclean and suppresses its dependent semantic checks | Committed cases `row-width-decisions` → `ROW_WIDTH\|Decisions\|expected=4\|actual=5\|row=DECISION-acme-platform-001` with `DECISIONS=3` and no link or default cascade; `row-width-assumptions` → `ROW_WIDTH\|Assumption records\|expected=8\|actual=7\|row=ASSUMPTION-acme-platform-001` with `ASSUMPTIONS=1` |

Both twins were changed in the same edit; the Bash awk program now holds the canonical header texts and per-register widths in `BEGIN`, treats a non-canonical register as unparseable before any row is read, and computes a `usable[]` map (canonical **and** structurally clean) that every dependent check consults. The PowerShell twin received the same structure (`$registerCanonical`, `$registerClean`, `$usable`) and the same identifier regex; the switch arms lost their `-ge N` guards because exact widths are now guaranteed upstream. The PowerShell twin parses with `PARSE_ERRORS=0`.

Representative row-width coverage beyond the two committed cases was exercised as isolated mutations of `valid-baseline` in a throwaway copy under `scratch/` (never in the repository), one per remaining register, confirming that each defect yields exactly one `ROW_WIDTH` and no cascade:

| Register | Mutation | Observed diagnostic | Side effect |
| :--- | :--- | :--- | :--- |
| Intake metadata | `\| Size \| medium \|` → `\| Size \| medium \| extra \|` | `ROW_WIDTH\|Intake metadata\|expected=2\|actual=3\|row=Size` | counts unchanged, no `COUNT_CONTRADICTION` |
| Accepted defaults | `DEFAULT-acme-platform-001`'s adjacent-decisions cell removed | `ROW_WIDTH\|Accepted defaults\|expected=6\|actual=5\|row=DEFAULT-acme-platform-001` | `DEFAULTS=0`, no `DEFAULT_WIDENED` |
| Verification obligations | `OBLIGATION-acme-platform-001`'s `Destination` removed | `ROW_WIDTH\|Verification obligations\|expected=5\|actual=4\|row=OBLIGATION-acme-platform-001` | `OBLIGATIONS=0`, no `OBLIGATION_UNTRACKED`, no `DESTCHECK` |
| Round log | round 1 gains an `extra` cell | `ROW_WIDTH\|Round log\|expected=3\|actual=4\|row=1` | `ROUNDS=1`, no `COUNT_CONTRADICTION` |

No-cascade property, measured: with the Decisions register structurally unclean, the checker still counts 3 readable decisions and emits no `ASSUMPTION_LINK_UNRESOLVED` for the now-absent `DECISION-acme-platform-001` and no `DEFAULT_WIDENED`; with the Assumption records register unclean it emits no `ASSUMPTION_STILL_OPEN`. A defect in one register therefore reports itself once rather than fanning out into findings that describe consequences of the malformed row.

Two case expectations tightened as a direct consequence and are recorded in the manifest rather than papered over: `header-renamed` now reports `OBLIGATIONS=0` (previously 1) and `header-reordered` now reports `DECISIONS=0` (previously 4), because a register whose header is not canonical is no longer parsed positionally at all. Both were re-measured with the extracted checker before the manifest was updated.

The full matrix, the gate battery and the Windows-local parity run were repeated after this pass: 16 contracts on both twins, 16 identical case rows, `BASH_EXIT=0`, `PS_EXIT=0` (section 5).

## 13. Residual risks and limitations

- **CI wiring is unverified until pushed.** The YAML edits parse and the steps mirror existing ones, but only a real run proves the Windows runner executes the new PowerShell step.
- **Local PowerShell evidence is environment-limited.** The UNC run cannot report parity; the Windows-local copy can, and its repository-integrity check exercises a genuinely local `git` repository rather than the CI checkout. Native Windows CI is still the authoritative check.
- **Log encoding differs between twins** (measured in section 5). It cannot change a verdict because comparisons happen in string space, but any future consumer that parses redirected PowerShell output as UTF-8 will mis-read the section sign.
- **Register parsing requires markdown tables with the canonical header row.** A record that omits a register is rejected as `REGISTER_MISSING`, one that writes it as prose as `REGISTER_NOT_TABULAR`, and one whose header renames or reorders a column the same way; all three verdicts are correct for a contract stated over machine-readable registers, but this harness cannot validate a prose-only intake format, and a future format change must update the expected header rows, the per-register cell counts and the identifier regex in both twins.
- **Coverage is bounded to artifact shape.** The harness does not verify that an invariant in `docs/STATE.md` cites a real `DECISION-*` id, that a destination's content satisfies its obligation, that an accepted default's prose scope matches its declared scope, or that a human actually approved a decision. Those stay with the documentation-contract assertions and the bounded manual review.
- **A green matrix is not agent compliance.** Sixteen artifact shapes are classified as specified; nothing here shows that a live model produces consistent artifacts.

## 14. What this does not prove

It does not show that a running onboarding session preserves decision provenance, that every on-host mismatch is detected, or that any model follows the workflow. It proves that these sixteen generated artifact shapes are accepted or rejected exactly as the contract specifies, on both twins, and that the harness leaves the repository untouched.
