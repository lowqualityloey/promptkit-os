# Production Release Checklist: [Version / Release Name]

<!-- Replace the example anchor with the immutable Release ID, for example: <a id="RELEASE-2026-09-release"></a> -->
<a id="RELEASE-release-slug"></a>

> **Developer-friendly fill-in guide:** **Required** means the release record cannot be complete without a concrete value. **Optional** means record it when the condition applies and use the stated `N/A` value otherwise. **Not applicable** means the release or appendix does not use that concern, such as `N/A` for Trivial Work or a consumer repository. Prefer short evidence with a stable link, exact revision, command, result, and owner. For example, `Verification Link: [CHECK-123](../tests/checks.md#CHECK-123)` and `Verified Result: Pass` are stronger than `verified` alone.
>
> **Field status summary:** Release identity, version/tag, deploy lead, target environment, date, commit, linkage state, verification result, and resume condition are **Required**. Execution-control evidence is **Required when Controlled Work applies** and **Not applicable** otherwise. Internal release-evaluation fields are **Required when the PromptKit OS appendix applies**, **Optional** when conditional, and **Not applicable** for consumers. Environment, migration, smoke-test, observation, and rollback entries are **Required when that release concern exists**; record `None` or `N/A` only where the surrounding prompt permits it.
>
> **Acronym guide:** `CI` means Continuous Integration; `TDD` means Test-Driven Development; `QA` means Quality Assurance; `SemVer` means Semantic Versioning; `RPO/RTO` mean Recovery Point Objective/Recovery Time Objective; and `PII` means Personally Identifiable Information. The explanations are guidance only and do not change release, deployment, rollback, or approval ownership.

- **Release ID [Required]**: `RELEASE-<release-slug>`
- **Canonical Release Record Path [Required]**: `docs/releases/<release>.md`
- **Release Linkage State [Required]**: `pending | blocked | verified | linked_to_pk_ship`
- **CI Triage Link [Required when a CI failure exists]**: `[CI-<provider>-<run-id>](ci-triage/<ci-failure-id>.md#CI-<provider>-<run-id>)` or `N/A - no CI failure`
- **Verification Link [Required]**: `[<stable-id>](<relative-path>#<stable-id>)`
- **Verified Result [Required]**: `[Pass | Fail | Pending]`
- **Resume Condition [Required]**: `[Condition for the next release state or N/A]`

- **Release Version / Tag**: `v[X.Y.Z]`
- **Deploy Lead**: [Your Name / Team]
- **Target Environment**: [Production / Staging]
- **Release Date**: [YYYY-MM-DD HH:MM UTC]
- **Commit SHA**: `[commit-hash]`

---

## 1. Pre-Flight Verification

- [ ] All code merged to `main` with approved PR review (`pk:review`).
- [ ] All automated tests passing in CI per the project's verification (e.g. `pnpm test` / `pytest` / `cargo test` / `go test`; add `pnpm test:e2e` where an E2E suite exists).
- [ ] Build succeeds with zero bundle size alerts per the project's build (e.g. `pnpm build`).
- [ ] Git tag created and pushed: `git tag -a vX.Y.Z -m "..." && git push origin vX.Y.Z`.

## Execution-Control Evidence (Optional)

Use this section for Controlled Work. Enter `N/A` for Trivial Work or for a consumer repository that does not adopt the optional protocol.

- **Local Task Record**: `docs/tasks/<task-id>.md`
- **Task ID / Specification**: `[TASK-YYYY-MM-DD-slug]` / `[specification path]`
- **Execution Scope**: `[bounded files, artifacts, or behaviors]`
- **Execution State**: `[awaiting_review / completed]`
- **Owner / Approval Boundary**: `[owner]` / `[human approval boundary]`
- **Acceptance Results**: `[AC-* results and evidence]`
- **Changed-File Summary**: `[files and concise summaries]`
- **Candidate Branch / Revision**: `[branch] @ [exact revision]`
- **Verification and CI Evidence**: `[commands, results, workflow/run links]`
- **Review / Commit / Pull Request Evidence**: `[links or evidence]`
- **Latest Checkpoint / Handoff**: `[record links or N/A]`
- **Scope Change / Exception Records**: `[record links or N/A]`
- **Blockers and Resume Condition**: `[blocker, owner, evidence, and condition or None]`
- **Host / Timer Limitation**: `[record the limitation; do not claim live enforcement]`
- **Release-Impact Evaluation**: `[candidate assessment against the approved baseline]`

> Execution-control evidence supports durable traceability only. It does not authorize a tag, push, hosted release, publication, deployment, rollback, or any other external action. Release Coordinator approval remains separate and human-only.

## PromptKit OS Internal Release Evidence (Optional)

Use this appendix only for PromptKit OS's own release-evidence evaluation. Enter `N/A` for a consumer repository or when no internal release evaluation applies. These fields record analysis and decisions; they do not execute any release action.

- **Evaluation ID / Status / Date**: `[evaluation ID]` / `[preliminary | blocked | deferred | approved]` / `[YYYY-MM-DD HH:MM UTC]`
- **Applicability**: `PromptKit OS only`; consumer repositories: `N/A`
- **Latest Approved Release Record / Version Source of Truth**: `[record path, approved version, and source commit, or N/A for First Release]`
- **Prior Approved Release Commit**: `[exclusive baseline commit or N/A for First Release]`
- **First Release**: `[Yes | No]`
- **Release Range Start / End**: `[exclusive start]` / `[inclusive Release Candidate Commit]`
- **Release Candidate Commit**: `[exact candidate revision]`
- **Candidate-Inclusive Range Result**: `[Pass | Fail | Pending]`
- **Normalized Effective Change Set**: `[merge, squash, duplicate, revert, eligibility, and maintenance treatment summary]`
- **Normalization Blockers / Empty-Range Decision**: `[blocker or explicit coordinator decision, or None/N/A]`
- **Preliminary SemVer Candidate**: `[preliminary core version and optional prerelease identifier]`
- **Impact Precedence and Provenance**: `[greatest effective impact, supporting commits/evidence IDs, and candidate rationale]`
- **Prerelease / Promotion Record**: `[suffix and promotion provenance, or N/A]`
- **QA/Reviewer Result**: `[range, classification, normalization, precedence, blocker, and note-coverage result]`
- **QA - Every Release Note Has Supporting Contract Impact Evidence**: `[Pass | Fail | Pending]` - `[evidence references]`
- **QA - Every Effective Contract Change Has Exactly One Public Release Note**: `[Pass | Fail | Pending]` - `[effective change-set and note references]`
- **Reviewed Public Release Notes**: `[note references and both coverage results, or N/A]`
- **Reviewed Maintenance Release Notes**: `[omitted or labeled Maintenance, with references, or N/A]`
- **Draft Changelog State**: `Unpublished draft`
- **Draft Changelog Entries**: `[derived entries and note-to-changelog coverage result]`
- **Approved Release Record**: `[record path or N/A until separately approved]`
- **Approved Release Candidate Commit**: `[exact candidate revision or Not approved]`
- **Approved Release Range Start / End**: `[exclusive start]` / `[inclusive end]` or `Not approved`
- **Approved Release Version / Tag**: `[version]` / `[tag]` or `Not approved`
- **Candidate-versus-Approved Comparison**: `[Equal | Different with rationale | Not approved]`
- **Approval Difference Rationale**: `[required when approved version differs from the preliminary candidate, or N/A]`
- **Approval Decision / Coordinator / Date**: `[decision]` / `[coordinator]` / `[date]` or `Not approved`
- **Canonical Evaluation Authority**: `[release-evaluation-template record path; its approved candidate/range, rationale, QA result, and consistency table are authoritative]`
- **Consistency - Evaluation ID Linkage**: `[Pass | Fail | Pending | N/A]` - `[reference]`
- **Consistency - Candidate Membership**: `[Pass | Fail | Pending]` - `[reference]`
- **Consistency - Tag / Version Alignment**: `[Pass | Fail | Pending | N/A]` - `[reference]`
- **Consistency - Baseline Precedence**: `[Pass | Fail | Pending | N/A]` - `[reference]`
- **Consistency - Required Approval and Rationale**: `[Pass | Fail | Pending | N/A]` - `[reference]`
- **Consistency - QA / Note Linkage**: `[Pass | Fail | Pending]` - `[reference]`
- **Release-Consistency Results**: `[overall result and canonical evaluation reference]`

### Human-Only External-Action Decisions

Record decisions only. Do not execute actions from this appendix.

- **Tag Creation**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Hosted Release Creation**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Changelog Publication**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Remote Operations**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Deployment**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Rollback**: `[Not requested | Request human decision | Approved separately | Declined]`
- **External-Action Owner / Evidence**: `[Release Coordinator record or N/A]`

> A preliminary candidate, QA result, handoff, or checklist entry is not an approved release. Tagging, hosted release creation, changelog publication, remote operations, deployment, and rollback remain separate, explicit, human-approved decisions.

---

## 2. Environment Variables & Secrets Audit (use the project's native config mechanism; `env.ts` below is a TypeScript example)

| Variable Name | Required Scope | Verified in Prod Dashboard | Validated via native mechanism |
| :--- | :--- | :---: | :---: |
| `DATABASE_URL` | Server Only | [ ] | [ ] |
| `SESSION_SECRET` | Server Only | [ ] | [ ] |
| `STRIPE_SECRET_KEY` | Server Only | [ ] | [ ] |
| `NEXT_PUBLIC_APP_URL` | Public Client (e.g. `NEXT_PUBLIC_` for Next.js) | [ ] | [ ] |

---

## 3. Database Migration Sequencing (when persistence/schema exists; otherwise `N/A - <reason>`)

- **Migration Present**: [Yes / No / N/A]
- **Migration Type**: [Expand Phase (Additive) | Contract Phase (Cleanup) | None | N/A — one-shot/disposable/pre-deployment with rationale]
- **Escape Rationale** (when not using Expand-Contract): `[reason or N/A — live/compatibility-sensitive data must use Expand-Contract]`

### Sequencing Execution Plan (when migration present; otherwise `N/A`)
1. [ ] **Step 1**: [Run migrations before deploy / Deploy code first / N/A]
   - Command: `[project migrate command, e.g. pnpm db:migrate:deploy]`
2. [ ] **Step 2**: Trigger application code deployment.
3. [ ] **Step 3**: Verify active application pods report healthy status.

---

## 4. Post-Deployment Smoke Testing (interface-appropriate probes; HTTP examples below are for web services)

| Probe Target | Verification Command / URL | Expected Output | Actual Result |
| :--- | :--- | :--- | :--- |
| **System Health** | `GET /api/health` (or project's health signal) | `HTTP 200 { "status": "ok" }` or equivalent | Pass / Fail |
| **Authentication Flow** | Synthetic login test (where auth exists) | Session/token valid | Pass / Fail |
| **Critical User Flow** | [e.g., Create invitation or checkout] | Resource persisted / observable effect | Pass / Fail |
| **Client Bundle Check** (web clients only) | Production URL in incognito | Zero unhandled browser console errors | Pass / Fail |

---

## 5. Post-Release Observation Window (use release-specific thresholds defined before deploy; 15 min / values below are illustrative defaults)

- [ ] Error tracking inspected vs release thresholds (e.g. Sentry: zero new unhandled spikes).
- [ ] Latency within release thresholds (e.g. P99 < 250ms where HTTP/latency applies).
- [ ] Resource utilization within release thresholds (e.g. DB pool < 60% where applicable).

---

## 6. Rollback Runbook (In Event of Incident)

- **Application Rollback Command / Action**:
  - [e.g., Redeploy previous deployment ID via platform CLI / Vercel dashboard / git checkout]
- **Database Action** (when persistence exists; otherwise `N/A`):
  - [e.g., Schema was verified Expand-compatible with previous version; no database rollback required unless migration is the demonstrated cause — otherwise record recovery procedure]
- **Sign-off**:
  - Release Status: [Successful | Rolled Back | Investigating]
  - Notes: [Any follow-up items or technical debt to track]
