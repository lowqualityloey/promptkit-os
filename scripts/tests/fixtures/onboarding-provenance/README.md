# Onboarding provenance consistency fixtures

Fixture family for the onboarding **Artifact Provenance Contract** in
`protocols/discovery-intake.md` section G. It supplies the regression coverage
that Issue #641 Scenario 6 named but did not ship: the superseded-assumption,
accepted-default-widening, and intake-metadata/obligation inconsistency families,
plus structural cases for an artifact that drops a required register, for one
whose register is present as prose instead of a table, and for ones whose
register header is renamed or reordered.

## What a case contains

Each case is an artifact set produced by an onboarding run:

```
cases/<case-name>/expected-output/docs/specs/<date>-intake-acme-platform.md
cases/<case-name>/expected-output/docs/STATE.md
```

The Intake Record carries the machine-readable registers (Decisions, Accepted
defaults, Assumption records, Verification obligations, Intake metadata, Round
log). `docs/STATE.md` is the destination those registers point at, so a
destination claim can be resolved instead of asserted.

Each required register must carry its expected table header and separator row
with the expected columns, in the expected order: the checker compares the whole
header row by name and position, so a missing, renamed, substituted, or reordered
column makes the register unparseable. An intentionally empty table stays legal;
prose under the heading does not, because a register the reader cannot parse must
not read as "nothing to report".

`expected/cases.tsv` holds one row per case: case name, expected exit code, the
exact summary line, and the complete normalized diagnostic set (`-` for a valid
case). Diagnostics are compared as a complete set, not a sample. Both harnesses
fail closed on the manifest itself: a case directory under `cases/` with no
manifest row, a row that does not have exactly four tab-separated fields
(including a trailing tab, a repeated tab that leaves an empty field, or a fifth
field), an empty case name, or an expected exit code that is not numeric is a
`HARNESS_FAILURE`, never a skipped case.

## Covered contract rules

| Rule | Contract text | Diagnostic codes | Cases |
| :--- | :--- | :--- | :--- |
| 3 bounded defaults | "Accepting one default resolves only that decision." | `DEFAULT_WIDENED` | `default-widened` |
| 4 assumption lifecycle | "Do not delete the assumption and do not leave it listed as open." | `ASSUMPTION_STILL_OPEN` | `assumption-still-open` |
| 5 residual risk survives resolution | Re-home residual operational risk before closing an assumption. | `RESIDUAL_RISK_UNTRACKED` | `residual-risk-untracked` |
| 6 obligations stay owned and tracked | "An obligation missing any of the three is untracked." | `OBLIGATION_UNTRACKED`, `OBLIGATION_DESTINATION_MISSING` | `obligation-untracked` |
| 7 no arithmetic without a count | Counts are asserted only when the record tracks them. | `COUNT_CONTRADICTION`, `QUESTION_BUDGET_EXCEEDED` | `count-contradiction`, `question-budget-exceeded` |
| 4 assumption link integrity | An assumption may only claim a decision that exists in the Decisions register. | `ASSUMPTION_LINK_UNRESOLVED` | `assumption-link-unresolved` |
| 6 registers present and tabular | Keep all six registers distinct and present, each with its canonical header row (every column name, in order) and separator row, so a missing or unparseable register cannot read as "nothing to report". | `REGISTER_MISSING`, `REGISTER_NOT_TABULAR` | `register-missing`, `register-not-tabular`, `header-renamed`, `header-reordered` |

`valid-baseline` is the positive control: every rule holds, including an
assumption that stays legitimately open because its linked decision is itself
unresolved. Every other case is a genuine negative control: the defective
artifact must be rejected, and the harness fails if it is not.

## Deliberately out of scope

- **Rule 1, 2 and 8** (no implied promotion, traceable locks, designated
  precedence) stay with the static documentation-contract assertions and the
  manual review checklist, which already cover them.
- **Derived baselines** are not validated here; the existing behavioral-contract
  assertions own that surface.
- These harnesses read generated Markdown artifacts directly. They do not run an
  onboarding engine, and they do not execute a language model.

## Enforcement boundary

A green matrix proves that these twelve artifact shapes are classified as
specified: the checker accepts the consistent record and rejects each named
inconsistency with a stable diagnostic. It does not prove that a live model
produces consistent artifacts, that a reviewer notices every remaining
inconsistency, or that an artifact absent from these samples is handled
correctly. Those claims stay with the documented bounded human review.
