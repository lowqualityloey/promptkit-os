# Doctor Workflow (Installed Governance Audit)

## Fast Shorthand
Trigger anytime with: `pk:doctor`

No aliases: the spec registers none, and any bare `pk:` alias would first have to join the alias allowlist in `scripts/validate-references.sh` (and its `.ps1` twin) plus the orphan-trigger check, which requires zero warnings.

## Mission
One command checks hosts × engine version × install-mode × ignore-state × docs-drift and reports exactly what rotted: a stale engine, missing host directive blocks, unexpectedly ignored managed paths, diverged state stores. "pk stopped working and nobody noticed" becomes impossible. `pk:doctor` diagnoses; it never repairs.

## Level
**Level 2 (Controlled).** A new workflow is a public contract surface under [`docs/adrs/0002-workflow-lifecycle-policy.md`](../docs/adrs/0002-workflow-lifecycle-policy.md) (proposed SemVer impact `minor`). The workflow is **read-only**: it observes and reports, following the Phase 1 framing of [`workflows/sync.md`](./sync.md).

## Non-Overlap (ADR 0002 Gate Record)
- [`workflows/sync.md`](./sync.md) **repairs/updates** the engine (disk re-read, directive re-injection, upgrade execution per #545); `pk:doctor` only *reports* drift and never fetches, pulls, upgrades, or rewrites a directive.
- [`workflows/verify-bootstrap.md`](./verify-bootstrap.md) generates a verification surface for the *host application* (greenfield `verify/` scaffolding); `pk:doctor` audits *PromptKit's own installed governance* (engine, host directive files, ignore rules, state stores), not the host app's test coverage.
- [`workflows/route.md`](./route.md) classifies a task and routes to a workflow and ceremony level; `pk:doctor` performs no routing and never reclassifies work.
- `scripts/validate-references.sh` checks markdown reference integrity (files, links, triggers) and runs only in CI; `pk:doctor` runs in-session and audits installation health, not link targets.

## Non-Negotiable Guardrail: Read-Only by Default
`pk:doctor` reports; it never edits, stages, commits, or writes unless an explicit `--fix` is passed, and `--fix` is limited to re-emitting a host directive block. It never runs an upgrade; upgrade execution is owned by `workflows/sync.md` / #545. The engine is `scripts/check-doctor.sh` / `scripts/check-doctor.ps1` (twins), both read-only: allowed operations are exactly file reads plus `git check-ignore`, `rev-parse`, `rev-list`, and `merge-base`.

---

## Preconditions
- Workspace read access to the engine directory, `PROMPTKIT.md`, `docs/`, and the installed host files.
- The installer-written `profile:` line in `PROMPTKIT.md` is readable; it, together with the courier's `<kit>/.git` discriminator, scopes every expectation below.
- If neither the engine directory nor `PROMPTKIT.md` can be located, `pk:doctor` itself lacks a prerequisite → exit `2`, no rows emitted.
- `git` and the state stores are *soft* preconditions: their absence degrades the owning check to `SKIP(<reason>)`, never to exit `2`.

---

## 3-Phase Diagnostic Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                    PK:DOCTOR LIFECYCLE                      │
├──────────────────────────────┬──────────────────────────────┤
│ Phase 1: Scope & Install     │ Phase 2: Four Checks         │
│ Mode                         │ (hosts/version/ignore/docs)  │
├──────────────────────────────┴──────────────────────────────┤
│ Phase 3: Machine-Readable Report & Exit Code                │
└─────────────────────────────────────────────────────────────┘
```

### Phase 1: Scope & Install Mode
1. Resolve the engine directory (the `<kit-path>` quoted in the injected directive) and read the installer-written `profile:` from `PROMPTKIT.md`.
2. Classify the install door from the courier's own discriminator, exactly as `package/bin/promptkit-os.js` tests it: `<kit>/.git` exists → submodule/clone; absent → npx courier tarball.
3. Enumerate expected host files and workflows **from the declared mode**: a Lite install expects only its 6 workflows, so no row may report `MISSING` for a Balanced-only workflow (mode-scoping is a correctness rule, not a cosmetic one).

### Phase 2: The Four Checks

**1. hosts**: enumerate the expected host directive files from the declared profile; report `OK` when `<!-- PROMPTKIT_START -->` is present in each, `MISSING` when absent (remediation: re-run the installer). Scope by declared mode per Phase 1.

**2. version**: delegate to [`workflows/sync.md`](./sync.md#engine-version-drift-audit)'s six-state table; never re-derive the comparison. Map its states into this workflow's vocabulary:

| Six-state result | Doctor row |
| :--- | :--- |
| `ok` | `OK` |
| `behind(+n)` | `STALE(+n)` |
| `diverged` | `DIVERGED` |
| `unknown` | `SKIP(no engine stamp)` until #545 stamps the engine |
| `shallow-or-offline` | `SKIP(shallow/offline)` |
| `not-a-git-install` | `SKIP(not-a-git-install)`; version comes from the release tarball, not git |

**3. ignore-state**: run `git check-ignore -v` on the kit directory, `PROMPTKIT.md`, `docs/`, and the installed host files, using the three-way status branch pattern from `scripts/check-harness-security.sh`; report `IGNORED(<rule source>)` (naming the rule and its source line) or `OK`. An unexpected git exit status → `INCOMPLETE`, never `OK`.

**4. docs-drift**: compare `docs/STATE.md` §3A ↔ the latest canonical Task Record ↔ the harness handoff store. Agreement → `OK`; disagreement → `DIVERGED(<pair>)` with the exact differing field (e.g. `DIVERGED(STATE §3A vs Task Record): milestone`); a missing store or the unsettled three-store precedence contract (#550/#553) → `SKIP(<reason>)`.

**Degradation rule.** When an input is absent or a tool is missing (`handoff.md`, Task Records, `git`, `jq`), the owning check reports `SKIP(<reason>)` and does not affect the exit code. Never report `OK` for a check that did not run.

**Provenance Invariant.** No executed proof → no green claim: a row may read `OK` only when its check actually executed this run; anything not executed reads `SKIP(<reason>)`.

### Phase 3: Machine-Readable Report & Exit Code

**Output contract.** One line per check, tab-separated, fields in stable order, parseable by `grep`/`awk`:

```text
<scope>\t<STATUS>\t<detail>\t<remediation>
```

Status vocabulary: `OK` | `STALE` | `MISSING` | `IGNORED` | `DIVERGED` | `SKIP` | `INCOMPLETE`.

**Exit-code contract:**

| Code | Meaning |
| :--- | :--- |
| `0` | Every configured check is `OK`, `IGNORED`, or `SKIP` |
| `1` | At least one `STALE`, `MISSING`, `DIVERGED`, or `INCOMPLETE` finding |
| `2` | `pk:doctor` could not run at all (missing prerequisite) |

- `IGNORED` **never** contributes to exit `1`: a path the developer intentionally ignores is a valid configuration, not a health failure.
- `INCOMPLETE` is **fail-closed** and contributes to exit `1`, never `0` and never `2`. Exit `2` means no check ran because `pk:doctor` itself lacked a prerequisite; `INCOMPLETE` means a check *did* run and could not establish its answer.
- Precedence when both apply: `2` only when no check could run at all, otherwise `1`. Both twins must implement this line identically.

---

## Completion Criteria
- [ ] Every configured check emitted exactly one TAB-separated row in `<scope>\t<STATUS>\t<detail>\t<remediation>` order.
- [ ] Every `OK` row is backed by a check executed this run (Provenance Invariant); every non-executed check reads `SKIP(<reason>)`.
- [ ] Exit code matches the contract above, including `IGNORED` → `0`, `INCOMPLETE` → `1`, and `2` only when nothing could run.
- [ ] Mode-scoped expectations hold: no `MISSING` row for a workflow outside the declared profile.
- [ ] Zero writes, stages, commits, or upgrades performed; with `--fix`, only a host directive block was re-emitted.
- [ ] `scripts/check-doctor.sh` and `scripts/check-doctor.ps1` produce identical rows and exit codes for the same input.

## Related References
- Engine version delegation: [`workflows/sync.md`](./sync.md#engine-version-drift-audit), the Engine Version & Drift Audit six-state table.
- Structural template (the 25th workflow, and the precedent for this one): [`workflows/verify-bootstrap.md`](./verify-bootstrap.md).
- Workflow admission gate: [`docs/adrs/0002-workflow-lifecycle-policy.md`](../docs/adrs/0002-workflow-lifecycle-policy.md) §1.
- Routing boundary: [`workflows/route.md`](./route.md#the-engineering-lifecycle-decision-matrix).
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md).
