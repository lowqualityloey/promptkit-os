# Ship Workflow (Release Engineering, Migration Sequencing & Rollback Protocols)

## Fast Shorthand
Trigger anytime with: `pk:ship` (or `/pk-ship`)

## Mission
Guide the developer through safe, reliable production releases, deployment sequencing, and verification.

Eliminate production deployment outages: missing or invalid environment variables at runtime, race conditions between database migrations and application code deployments, unverified releases, and panicked rollbacks.

> **Developer-friendly ship guide:** Treat each release step as a recordable decision, not an implicit action. **Required** evidence identifies the exact revision, environment, command or probe, result, and accountable owner. Use **Not applicable** only with a reason, and use `None` only when there is genuinely no item to record. `CI` means Continuous Integration, `QA` means Quality Assurance, `PII` means Personally Identifiable Information, and `SemVer` means Semantic Versioning. **Example:** `Verification: GET /api/health returned HTTP 200 at the release revision` is clearer than `smoke test passed`. These explanations clarify the workflow without changing its human-only approval boundaries.
>
---

## Preconditions
- Code has passed code review (`pk:review`) and testing gates (`pk:test`).
- Target storage directory: `./docs/releases/` in the host project.
- Access to `.promptkit/templates/release-checklist.md`.

---

## Core Release Engineering Pillars

### 1. Runtime Environment Variable Validation (Fail-Fast Boot)
Never allow an application with missing or malformed secrets to boot into production:

1. **Type-Safe Schema Validation at Startup**:
   - Validate `process.env` using Zod or `@t3-oss/env-nextjs` inside an `env.ts` configuration module imported at the application entrypoint:
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
3. **Client vs Server Boundary**:
   - Never prefix server secrets with `NEXT_PUBLIC_` or `VITE_`.
   - Audit client bundle outputs to verify zero server secret leakage.

---

### 2. Zero-Downtime Migration Sequencing
Database schema changes and application code updates do not deploy at the exact same instant. Follow the **Golden Deployment Rule**:

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

- **Hard Rule**: Never combine an additive change (Expand) and a destructive drop (Contract) in the same release or migration script.

---

### 3. Staging and Preview Environment Parity
1. **Ephemeral Preview Deployments**:
   - Verify features in preview environments (Vercel previews, Supabase database branch, Railway staging) before merging to `main`.
2. **Data Sanitization**:
   - Non-production environments must use synthetic seed fixtures.
   - Never replicate unmasked production customer PII or payment records into staging environments.

---

### 4. Release Pre-Flight and Automated Smoke Testing
Before declaring a release complete, verify production behavior with active probes:

1. **Pre-Flight Sanity Check**:
   - Clean git tag generated: `vX.Y.Z`.
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
Trigger an immediate rollback if within 15 minutes of deployment:
- HTTP 5xx error rate spikes above 1%.
- P99 latency degrades by more than 50% from baseline.
- Core checkout, authentication, or data persistence flows fail in smoke tests.

#### Execution Runbook
1. **Application Code Rollback**:
   - Redeploy the previous verified commit SHA or platform deployment immediately (1-click rollback in Vercel, Railway, or Kubernetes).
2. **Database Reversion**:
   - Because all pre-deploy migrations follow the Expand phase, the database schema remains 100% compatible with the previous application version. **Do not roll back database schema during an active incident** unless the migration itself degraded database performance.
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

Task 6 defines this evidence-first entry path, bounded linkage, and action-confirmation boundary. Task 12 owns the later state-transition implementation, declined-action lifecycle, release handoff behavior, and valid or invalid fixtures. Do not implement those deferred mechanics here.

### Execution-Control Release Evidence Gate

Before Step 3, record the execution evidence needed by the release evaluation:

- Link the canonical Task Record(s), accepted completion evidence, changed-file summary, exact candidate revision, review result, CI evidence, migration sequencing, rollback plan, and any Scope Change or Exception Records.
- Confirm the task and milestone are in a releasable state and that no unresolved blocker, hard checkpoint, stale handoff, scope mismatch, or revision mismatch remains.
- Link the applicable release-impact evaluation and preserve the distinction between a preliminary candidate and an Approved Release Version.
- Record host/timer limitations and any execution-control validator result as evidence only. A passing validator or CI job cannot approve a version or authorize a tag, hosted release, publication, deployment, or rollback.
- Release Coordinator approval remains explicit and separate. The existing Step 3-5 actions, release checklist, production safety gates, and rollback authority remain owned by `pk:ship` and must not be automated by this overlay.

### Release Evidence Template Cross-Reference

Use the optional **Execution-Control Evidence** section in `templates/release-checklist.md` for the Task Record path and ID, specification, state, owner/approval boundary, acceptance and changed-file evidence, candidate revision, verification/CI/review/commit/PR links, checkpoint/handoff, scope or exception records, blockers, host/timer limitation, and release-impact evaluation. `N/A` is valid for Trivial Work or consumers that do not adopt the optional protocol. This evidence evaluates a candidate against the approved immutable `v1.0.0` baseline; it does not rewrite that baseline or authorize tag, push, publication, deployment, or rollback.

### Canonical Artifact Linkage

Use the shared [`Canonical Artifact Contract`](../docs/WORKFLOW-MAP.md#canonical-artifact-contract) for release linkage. Save the existing release record at `docs/releases/<release>.md`, expose `RELEASE-<release-slug>` as an explicit anchor, and link the verified result and resume condition there. For a CI failure, link the canonical `CI-<provider>-<run-id>` record from `docs/releases/ci-triage/<ci-failure-id>.md#CI-<provider>-<run-id>` only after the CI record is `verified`; the release record then reaches `linked_to_pk_ship` only after that verified result and its Verification Link, Verified Result, and Resume Condition are recorded. A CI record never becomes release approval. Task 12 owns the future state-transition and release-handoff implementation.

### PromptKit OS Internal Release Evaluation

This repository's release-candidate evaluation procedure is maintained separately in [`docs/internal/release-evaluation.md`](../docs/internal/release-evaluation.md) and applies only to this repository. Load it only when performing a release evaluation **in this repository**; consumer repositories do not inherit this internal governance pack.

- **Evaluation & Baseline**: Any unresolved blocker leaves the evaluation unapproved.
- **QA & Blocker Review**: The QA/Reviewer must conduct a Blocker review; any correction/re-review must be recorded.
- **Release Notes & Records**: Every public contract change requires Public Release Notes with exactly one supported note entry, draft Changelog Entries, and an Approved Release Record aligning the Approved Release Tag with the Approved Release Version.
- **External Actions**: External-action decisions remain data-only records; `pk:ship` must not automatically run tag commands, push refs, publish changelogs, deploy, or execute rollbacks.

`pk:ship` Steps 3–5 and the production-safety guidance below remain in force regardless.

---

### Step 3: Trigger Production Deployment
1. Create a version tag (`git tag -a vX.Y.Z -m "Release message"`).
2. Push to production deployment pipeline.

### Step 4: Execute Post-Deploy Smoke Testing
1. Run automated health check endpoints and inspect deployment logs.
2. Manually or synthetically verify the primary user journey in production.

### Step 5: Monitor and Sign-off
1. Monitor error tracking (Sentry / Datadog / CloudWatch) for 15 minutes post-deploy.
2. Complete and commit the release record to `./docs/releases/`.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Consequence | Remedy |
| :--- | :--- | :--- |
| **Unvalidated Environment Variables** | Silent crashes hours after deploy when missing secrets are first accessed. | Validate all environment variables with Zod at application startup. |
| **Deploying Code and Migration Simultaneously** | Container start races against migration execution, causing broken queries during rolling update. | Follow the Golden Deployment Rule (Expand before deploy; Contract after deploy). |
| **Debugging Live in Production** | Extended customer downtime while developers scramble under pressure. | Roll back immediately; debug safely in local development using `pk:debug`. |
| **Untested Rollbacks** | Rollback fails because new schema broke backwards compatibility with old code. | Ensure every schema migration is backwards-compatible with previous application version. |
| **Skipping Smoke Tests** | Broken client bundles or routing errors discovered by customers instead of engineers. | Run automated smoke tests immediately post-deployment. |

---

## Completion Criteria
- Environment variables validated with startup schema checks.
- Migration sequencing planned and executed in correct phase order.
- Post-deployment smoke tests executed and passed.
- Release document saved to `./docs/releases/`.
