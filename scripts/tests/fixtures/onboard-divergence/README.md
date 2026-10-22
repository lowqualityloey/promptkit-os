# Onboarding Divergence Fixtures

These fixtures are synthetic and local-only: no real identifiers, secrets, or network access.

- `cases/<case-name>/project/` holds the simulated host project, including the pre-existing `ARCHITECTURE.md` that onboarding must read but never modify.
- `cases/<case-name>/expected-output/` holds the specified onboarding output for that project: the generated `PROMPTKIT.md`, the generated `docs/STATE.md`, and the Intake Record under `docs/specs/` that owns the host-document divergence rows.
- `expected/cases.tsv` is the shared manifest: case name, expected exit code, exact summary line, and the complete normalized diagnostic set (`;;` separated, `-` for a valid case).

Coverage:

- `one-conflicting-architecture`: a three-line `ARCHITECTURE.md` and one contradictory confirmed decision produce exactly one divergence row whose precedence stays `unresolved` until a human designates it; the record states that no human designation has been recorded, and the generated profile states the same unresolved precedence with its source.
- `designated-precedence`: the same conflict with an explicit human designation of `decision-authority` (approver, date, record path); the record documents that designation, the generated profile states that designated precedence against the same `DIVERGENCE-*` id, and the next action asks for host-architecture reconciliation instead of another designation.
- `precedence-without-designation`: a concrete precedence value with no human designation is rejected. This case keeps a concrete precedence on purpose: it is the negative control proving the harness rejects a precedence nobody designated.
- `untraceable-precedence-claim`: an override claim about `ARCHITECTURE.md` with no source reference is rejected, while the generated profile still states the unresolved precedence with its source.

The Bash and PowerShell harnesses run the same matrix, compare the complete normalized diagnostic set and the exact summary against the shared manifest, and assert that the host document SHA-256 is identical before and after the simulated onboarding write.

Precedence consistency is pinned as well. The generated profile must state the precedence the Intake Record records (`PROFILE_PRECEDENCE_MISMATCH` when it states a different one, `PROFILE_PRECEDENCE_MISSING` when it states none), and a row that already carries a human designation must not ask for another one in its next action (`NEXT_ACTION_REASKS_DESIGNATION`). Those three checks are skipped for a row that is already invalid, so the negative control keeps exactly one diagnostic.

Enforcement honesty: onboarding is a Markdown workflow, not an executable artifact generator. These harnesses validate the specified sample output and its integrity properties; they do not execute an onboarding engine, and they cannot prove that a live model detects every semantic contradiction.

Run the paired harnesses from the repository root:

```text
bash scripts/tests/run-onboard-divergence-fixtures.sh
pwsh -NoProfile -File .\scripts\tests\run-onboard-divergence-fixtures.ps1
```
