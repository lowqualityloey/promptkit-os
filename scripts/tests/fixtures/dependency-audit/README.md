# Dependency Audit Gate Fixtures

Synthetic, local-only inputs for `scripts/tests/verify-dependency-audit-gate.mjs`. No network, no `npm` invocation, no real advisory ids, no real package names.

- `npm-audit-report.json` is a realistic `npm audit --json` payload. Its `via` entries carry the shape the real command emits: `source` is a numeric advisory id and `url` is a full `https://github.com/advisories/GHSA-...` link. That shape is the whole point of the fixture — a gate that compares the ledger against `via.source` or the raw `via.url` can never match, and this payload makes that failure visible.
- `audit-exceptions.json` is the exception ledger. It holds one active exception, one expired exception, and one active exception for a critical advisory, so the same payload exercises suppression, expiry re-opening, and the severity threshold at once.

The report covers eight advisories across the interesting cases:

| Package | Severity | Ledger state | Expected |
| --- | --- | --- | --- |
| `example-parser` | high | active exception | suppressed |
| `patched-lib` | critical | active exception | suppressed |
| `legacy-crypto` | critical | expired exception | blocks |
| `tiny-http` | high | no exception | blocks |
| `wrapper-pkg` | high | `via` is a bare package name | blocks |
| `multi-vuln` | high | one of two advisories excepted | blocks |
| `dev-linter` | moderate | no exception | below threshold |
| `safe-util` | low | no exception | below threshold |

`wrapper-pkg` is the second `via` shape: npm emits a plain string when the advisory is inherited from a dependency rather than reported directly. The recipe's gate must not crash on it.

`multi-vuln` is the aggregation case. It carries two advisories, `GHSA-pppp-qqqq-rrrr` (excepted) and `GHSA-zzzz-yyyy-xxxx` (not), so a gate that suppresses the whole package when any one advisory is excepted will let it through. The correct gate blocks it: an exception covers the advisory it names, never the package.

Run the harness from the repository root:

```text
node scripts/tests/verify-dependency-audit-gate.mjs
```

It is also wired into `scripts/tests/run-playbook-contract-tests.sh` and its PowerShell twin, so CI runs it with the rest of the playbook contract suite.
