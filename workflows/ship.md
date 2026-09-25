# Ship Workflow (Release Engineering, Migration Sequencing & Rollback Protocols)

## Fast Shorthand
Trigger anytime with: `pk:ship` (or `/pk-ship`)

## Mission
Guide the developer through safe, reliable production releases, deployment sequencing, and verification.

Reduce preventable production deployment failures: missing or invalid environment variables at runtime, race conditions between database migrations and application code deployments, unverified releases, and panicked rollbacks.

> **Developer-friendly ship guide:** Treat each release step as a recordable decision, not an implicit action. **Required** evidence identifies the exact revision, environment, command or probe, result, and accountable owner. Use **Not applicable** only with a reason, and use `None` only when there is genuinely no item to record. `CI` means Continuous Integration, `QA` means Quality Assurance, `PII` means Personally Identifiable Information, and `SemVer` means Semantic Versioning. **Example:** `Verification: GET /api/health returned HTTP 200 at the release revision` is clearer than `smoke test passed`. These explanations clarify the workflow without changing its human-only approval boundaries.
>
---

## Preconditions
- Code has passed code review (`pk:review`) and testing gates (`pk:test`).
- Target storage directory: `./docs/releases/` in the host project.
- Access to `templates/release-checklist.md`.

---

## Core Release Engineering Pillars

### 1. Runtime Environment Variable Validation (Fail-Fast Boot)
Never allow an application with missing or malformed secrets to boot into production:

1. **Native Configuration Validation at Startup**:
    - Validate all production configuration and secrets at the application's startup or deployment boundary using the project's native configuration mechanism. Fail before serving production traffic when required configuration is missing or malformed.
    - Web-application example (TypeScript): validate `process.env` using Zod or `@t3-oss/env-nextjs` inside an `env.ts` configuration module imported at the application entrypoint:
     ```typescript
     // src/env.ts
     import { z } from 'zod';

     const serverEnvSchema = z.object({
       NODE_ENV: z.enum(['development', 'test', 'production']),
       DATABASE_URL: z.string().url(),
       SESSION_SECRET: z.string().min(32),
       STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
     });

     const clientEnvSchema = z.object({
       NEXT_PUBLIC_APP_URL: z.string().url(),
     });

     export const env = {
       ...serverEnvSchema.parse(process.env),
       ...clientEnvSchema.parse(process.env),
     };
     ```
2. **Fail-Fast Crash**:
   - If a required secret is missing, the application process crashes immediately during initialization with an explicit error naming the missing variable. It must never fail hours later during an active user transaction.
3. **Client vs Server Boundary** (applications with a browser-built client bundle; otherwise record `N/A - <reason>`):
    - Never prefix server secrets with the client-exposed prefix of the project's framework (e.g. `NEXT_PUBLIC_` for Next.js, `VITE_` for Vite).
    - Audit client bundle outputs to verify zero server secret leakage.

---

### 2. Zero-Downtime Migration Sequencing
For production systems where multiple application revisions may coexist or rollback compatibility matters, evaluate Expand-Contract sequencing. Database schema changes and application code updates do not deploy at the exact same instant. Follow the **Golden Deployment Rule** (default pattern for live or compatibility-sensitive data; if inapplicable — disposable or pre-deployment database, first deploy with no prior version, one-shot migration, or a system where concurrent versions cannot exist — record the reason and applicable compatibility/rollback evidence):

```
EXPAND PHASE (Additive Changes):
Step 1: Apply backwards-compatible database migration (new nullable columns/tables).
Step 2: Deploy new application code (writes to both old and new columns).
Result: Zero downtime. Both old and new application instances function concurrently.

CONTRACT PHASE (Destructive Cleanups):
Step 1: Deploy application code that completely stops reading/writing old column.
Step 2: Verify all old containers/pods are terminated and zero traffic references old schema.
Step 3: Apply database migration to drop deprecated column or table.
Result: Zero downtime. No running instance queries a deleted column.
```

- **Hard Rule**: Never combine an additive change (Expand) and a destructive drop (Contract) in the same release or migration script when Expand-Contract applies (live or compatibility-sensitive data).

---

### 3. Staging and Preview Environment Parity
1. **Representative Pre-Production Environments**:
    - Validate the release candidate in an environment sufficiently representative of production before production deployment, when such an environment exists. Examples: ephemeral preview deployments (e.g. Vercel previews, Supabase database branches, Railway staging) verified before merging to `main`.
2. **Data Sanitization**:
   - Non-production environments must use synthetic seed fixtures.
   - Never replicate unmasked production customer PII or payment records into staging environments.

---

### 4. Release Pre-Flight and Automated Smoke Testing
Before declaring a release complete, verify production behavior with active probes:

1. **Pre-Flight Sanity Check**:
   - Clean git tag proposed (do not generate or push without human authorization): `vX.Y.Z`.
   - CI pipeline passed: lint, type-check, unit tests, integration tests.
   - Build artifact size verified (check for bundle size regressions).
2. **Automated Smoke Test Verification**:
   - Immediately after traffic shifts to the new release, run automated synthetic probes:
     - **Health Check**: `GET /api/health` returns `200 OK` with database ping latency.
     - **Critical Path Probe**: Synthetic test user authenticates, loads dashboard, and performs a read.
     - **Edge Cache Invalidation**: Verify stale CDN assets are purged.

---

### 5. Instant Rollback Protocol
When production metrics degrade post-release, do not guess or attempt complex live debugging in production. Follow the structured rollback protocol:

#### Rollback Decision Criteria
Use release-specific rollback thresholds defined before deployment and recorded in the release record. Where the project has no established thresholds, record explicit human-approved thresholds or state that automatic thresholding is unavailable. Illustrative defaults (calibrate per project — HTTP/latency signals are meaningless for batch, mobile, or low-volume systems without adaptation): trigger an immediate rollback if within 15 minutes of deployment:
- HTTP 5xx error rate spikes above 1%.
- P99 latency degrades by more than 50% from baseline.
- Core checkout, authentication, or data persistence flows fail in smoke tests.

#### Execution Runbook
1. **Application Code Rollback (human executes)**:
    - If the rollback criteria above are met, record a rollback proposal as an action block (proposed action, bounded scope, reversal action, resume condition) for the Release Coordinator — do not execute it. The prepared command (redeploy the previous verified commit SHA or platform 1-click rollback in Vercel, Railway, or Kubernetes) is recorded so the human can act immediately.
2. **Database Reversion**:
    - Production migrations intended to support rollback must preserve compatibility with the previous application version (Expand phase) — treat this as a verified precondition, not a guaranteed fact. **Do not roll back database schema during an active incident** unless the migration itself is the demonstrated cause and a separately verified database recovery procedure exists.
3. **Transition to Root Cause Analysis**:
   - After production stability is restored, trigger `pk:debug` in local development to reproduce the failure.

---

## Workflow Steps

### Step 1: Pre-Release Verification
1. Confirm all code passed review (`pk:review`) and quality gates (`pk:test`).
2. Verify that all required environment variables are provisioned in the production dashboard.

### Step 2: Determine Migration Sequencing
1. Check if the release contains database migrations:
   - If Expand phase: Execute migrations *before* deploying application code.
   - If Contract phase: Verify application code is deployed and verified *before* executing cleanup migrations.

### Evidence-First CI Failure Triage and Release Linkage

When a CI Failure is reported for a release candidate or a candidate under evaluation, use the shared [`Canonical Artifact Contract`](../docs/WORKFLOW-MAP.md#canonical-artifact-contract) and create or link the canonical CI Triage Record at `docs/releases/ci-triage/<ci-failure-id>.md`. The record exposes the immutable identity `CI-<provider>-<run-id>` and is owned by the CI triage owner. This section adds evidence and release linkage guidance to `pk:ship`; it does not create a second release authority or replace `pk:debug`, the Local Task Record, human approval, or existing rollback ownership.

#### 1. Collect evidence before classification or remediation

- Start the record in `evidence_requested` when the failure is reported. Collect evidence before classifying the failure or recommending a source change.
- The evidence bundle must identify the check, failed job or command, failure output, revision identifier, execution time, and relevant configuration context. Link the provider run or record the copied output and its source in the CI Triage Record.
- GitHub CLI retrieval is conditional and read-only: use it only when it is available and authenticated for the relevant repository, and only to retrieve run metadata or logs. Do not use it to retry a run, change repository configuration, deploy, roll back, or perform any other remote action.
- If GitHub CLI is unavailable, unauthenticated, inaccessible, or insufficient, request the provider run URL or copied output. Platform-neutral collection may use the provider's run page or export facility, the failed check and job names, the command and relevant log excerpt, the revision and execution time, and the configuration or environment context needed to interpret the failure. Never request or record secrets.
- If the evidence bundle is incomplete, keep the record in `evidence_requested`, record the missing evidence and its owner, and produce an evidence request only. Do not classify the failure or recommend a source-code change.

#### 2. Classify only sufficient evidence and bound remediation

- After the required evidence is recorded, set the record to `evidence_sufficient` and classify it as `test`, `static analysis`, `build`, `dependency or environment`, `infrastructure or transient`, `deployment`, or `unknown`.
- `unknown` is valid when the complete evidence bundle is present but the cause remains unresolved. It is not a substitute for missing logs or an inaccessible run.
- A Remediation Plan may be recorded only when the evidence supports one. It must state the classification, suspected cause, affected scope, minimal change, verification command, and rollback or reversal action. A plan is bounded evidence, not approval to execute it.
- Route local reproduction or debugging needs to `pk:debug`. An engineer records any in-scope source fix and its verification in the canonical Local Task Record; `pk:ship` does not edit source or replace the execution authority.

#### 3. Record each remote action as a separate human-confirmation block

For every proposed remote retry, repository configuration change, deployment, or rollback, add one independent action block in the CI Triage Record with identity `ACTION-<ci-id>-<nnn>`. Each block must record:

- Proposed Action.
- Confirmation State: `pending`, `confirmed`, or `declined`.
- Approver and Confirmation Timestamp. For a pending block, use `N/A - awaiting confirmation` for each field rather than implying approval.
- Bounded Scope.
- Reversal or Rollback Action.
- Resume Condition.

A pending action remains blocked until the human approver records a separate confirmation. Recording a confirmation never executes the action, and confirming or declining one action never authorizes or decides another. A declined action closes only that action; the parent CI Triage Record must receive a new bounded plan or become `blocked` with an owner and precise resume condition. No workflow, validator, or CI result may perform the remote action automatically.

#### 4. Link successful verification before release resumption

- Use the canonical CI states `evidence_requested`, `evidence_sufficient`, `classified`, `remediation_planned`, `awaiting_confirmation`, `local_reproduction_or_fix`, `verification_pending`, `verified`, `linked_to_pk_ship`, and `blocked` as defined by the shared contract. A record may become `blocked` from any state when it has an owner and precise resume condition.
- For a release candidate, link the Remediation Plan and successful Verification Evidence to the existing `pk:ship` pre-release record. Keep `pk:ship` release readiness blocked until the CI Triage Record contains Verification Evidence and reaches `verified`, then link `CI-<provider>-<run-id>` from `docs/releases/<release>.md` and record the release's Verification Link, Verified Result, and Resume Condition. The release linkage state is `linked_to_pk_ship` only after the verified result is linked.
- A classification, proposed remediation, empty blocker list, passing unrelated validator, or successful check that is not the recorded verification does not permit release resumption. A CI Triage Record never becomes release approval; Release Coordinator approval and external-action decisions remain separate.

Deferred mechanics (state-transition implementation, declined-action lifecycle, release handoff behavior, valid or invalid fixtures) are out of scope here. Do not implement them.

### Execution-Control Release Evidence Gate

Before Step 3, record the execution evidence needed by the release evaluation:

- Link the canonical Task Record(s), accepted completion evidence, changed-file summary, exact candidate revision, review result, CI evidence, migration sequencing, rollback plan, and any Scope Change or Exception Records.
- Confirm the task and milestone are in a releasable state and that no unresolved blocker, hard checkpoint, stale handoff, scope mismatch, or revision mismatch remains.
- Link the applicable release-impact evaluation and preserve the distinction between a preliminary candidate and an Approved Release Version.
- Record host/timer limitations and any execution-control validator result as evidence only. A passing validator or CI job cannot approve a version or authorize a tag, hosted release, publication, deployment, or rollback.
- Release Coordinator approval remains explicit and separate. Steps 3-5 below prepare proposals, verification plans, and records; executing tag, push, deployment, or rollback commands remains human-only (see Action Authority Model in `protocols/code-quality-gate.md`). Every approval request to the Release Coordinator renders the Decision Card per the Human Decision & Question Comprehensibility Contract in `protocols/code-quality-gate.md` (Type D — always human, card required).

### Pattern C Release Evidence Audit

Before Release Coordinator review, a Pattern C **evidence audit** verifies checklist claims:
- Confirm tag proposals are unexecuted proposals for the Release Coordinator (no git tags created or pushed).
- Confirm verification links resolve to valid artifacts, test logs, and CI triage records.
- Confirm rollback records exist with concrete rollback triggers, commands, and reversal procedures.
- The verifier operates under the single-pass Pattern C contract (recommendation-only report capped at $\le 15$ lines; creates no release or deployment authority).

### Release Evidence Template Cross-Reference

Use the optional **Execution-Control Evidence** section in `templates/release-checklist.md` for the Task Record path and ID, specification, state, owner/approval boundary, acceptance and changed-file evidence, candidate revision, verification/CI/review/commit/PR links, checkpoint/handoff, scope or exception records, blockers, host/timer limitation, and release-impact evaluation. `N/A` is valid for Level 0 Work or consumers that do not adopt the optional protocol. This evidence evaluates a candidate against the approved immutable `v1.0.0` baseline; it does not rewrite that baseline or authorize tag, push, publication, deployment, or rollback.

### Canonical Artifact Linkage

Use the shared [`Canonical Artifact Contract`](../docs/WORKFLOW-MAP.md#canonical-artifact-contract) for release linkage. Save the existing release record at `docs/releases/<release>.md`, expose `RELEASE-<release-slug>` as an explicit anchor, and link the verified result and resume condition there. For a CI failure, link the canonical `CI-<provider>-<run-id>` record from `docs/releases/ci-triage/<ci-failure-id>.md#CI-<provider>-<run-id>` only after the CI record is `verified`; the release record then reaches `linked_to_pk_ship` only after that verified result and its Verification Link, Verified Result, and Resume Condition are recorded. A CI record never becomes release approval. Future state-transition and release-handoff mechanics are out of scope here.

### PromptKit OS Internal Release Evaluation

This repository's release-candidate evaluation procedure is maintained separately in [`docs/internal/release-evaluation.md`](../docs/internal/release-evaluation.md) and applies only to this repository. Load it only when performing a release evaluation **in this repository**; consumer repositories do not inherit this internal governance pack.

- **Evaluation & Baseline**: Any unresolved blocker leaves the evaluation unapproved.
- **QA & Blocker Review**: The QA/Reviewer must conduct a Blocker review; any correction/re-review must be recorded.
- **Release Notes & Records**: Every public contract change requires Public Release Notes with exactly one supported note entry, draft Changelog Entries, and an Approved Release Record aligning the Approved Release Tag with the Approved Release Version.
- **External Actions**: External-action decisions remain data-only records; `pk:ship` must not automatically run tag commands, push refs, publish changelogs, deploy, or execute rollbacks.

`pk:ship` Steps 3–5 below prepare release actions, verification plans, and records; production-safety guidance stays in force as planning the human executor follows.

---

### Step 3: Prepare Production Deployment (human executes)
1. Prepare the version tag command (`git tag -a vX.Y.Z -m "Release message"`) as a proposal for the Release Coordinator — do not run it.
2. Prepare the production deployment plan (pipeline, migration order per Step 2, verification probes per Step 4) as a proposal — do not push, deploy, or publish. Each remote action is recorded as a separate human-confirmation block per the CI-triage action-block pattern.

### Step 4: Define Post-Deploy Smoke Verification (executor runs after deploy)
Specify the probes the release executor runs immediately after traffic shifts to the new release (see Pillar 4 definitions above):
1. Automated health check endpoints and deployment log inspection.
2. Manual or synthetic verification of the primary user journey in production.
Record expected results and pass thresholds now; the human-executed deploy is what puts them into effect.

### Step 5: Monitor Criteria and Release Record
1. Record the monitoring criteria for the 15-minute post-deploy window (error tracking in Sentry / Datadog / CloudWatch; rollback decision criteria above).
2. Draft the release record in `./docs/releases/` with revision, verification evidence, and sign-off status. Committing follows `pk:commit` with human confirmation — drafting the record does not approve the release.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Consequence | Remedy |
| :--- | :--- | :--- |
| **Unvalidated Environment Variables** | Silent crashes hours after deploy when missing secrets are first accessed. | Validate all production configuration with the project's native mechanism at application startup. |
| **Deploying Code and Migration Simultaneously** | Container start races against migration execution, causing broken queries during rolling update. | Follow the Golden Deployment Rule for live data (Expand before deploy; Contract after deploy); document the escape where it does not apply. |
| **Debugging Live in Production** | Extended customer downtime while developers scramble under pressure. | Roll back immediately; debug safely in local development using `pk:debug`. |
| **Untested Rollbacks** | Rollback fails because new schema broke backwards compatibility with old code. | Ensure every live-data schema migration is backwards-compatible with previous application version (verified precondition, not assumed). |
| **Skipping Smoke Tests** | Broken client bundles or routing errors discovered by customers instead of engineers. | Run automated smoke tests immediately post-deployment. |

---

## Completion Criteria
- Environment variables validated with startup schema checks using the project's native mechanism.
- Migration sequencing planned and executed in correct phase order (or escape documented with rationale where Expand-Contract does not apply).
- Post-deployment smoke verification defined with expected results and thresholds.
- Release document drafted in `./docs/releases/`.
- CI-triage linkage recorded (`linked_to_pk_ship` only after verified result, where a CI failure exists).
- Release-impact evaluation linked; preliminary candidate distinguished from Approved Release Version.
- Release Coordinator authorization recorded for every remote action; no tag, push, deploy, or rollback executed by the agent.
