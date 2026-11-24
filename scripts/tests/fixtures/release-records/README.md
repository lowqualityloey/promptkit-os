# Release-Record Validator Fixtures

These fixtures are synthetic, local-only Markdown records for the paired `validate-release-records` scripts. They contain no real repository identifiers, remote URLs, Git commands, tags, hosted releases, publication actions, deployments, or rollback actions.

Run a valid set with:

```text
bash scripts/validate-release-records.sh --root scripts/tests/fixtures/release-records/valid --strict
pwsh -NoProfile -File .\scripts\validate-release-records.ps1 -Root .\scripts\tests\fixtures\release-records\valid -Strict
```

The `cases/` directories intentionally contain one focused malformed condition each. Expected diagnostic categories include `MISSING_FIELD`, `RANGE_MEMBERSHIP`, `APPROVAL_REQUIRED`, `TAG_VERSION_MISMATCH`, `VERSION_PRECEDENCE`, `EVALUATION_ID_MISMATCH`, `QA_NOTE_LINKAGE`, `EMPTY_RANGE_DECISION`, `BREAKING_GUIDANCE_MISSING`, and `OUTCOME_SECTION`. A validator result is evidence only; it never approves a release or performs an external action.

The `empty-range-deferred/` directory is a positive control for an explicit defer decision. Every identifier in this fixture tree is synthetic.
