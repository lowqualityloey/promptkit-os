# Atomic Conventional Commit Workflow

## Fast Shorthand
Trigger anytime with: `pk:commit` (or `/pk-commit`)

## Mission
Transform uncommitted workspace diffs into clean, atomic, high-signal Conventional Commits. Prevent accidental secret leaks, purge temporary debug probes, and enforce single-concern commit boundaries.

---

## Preconditions
- Active Git repository with uncommitted changes (`git status -s` shows modifications).
- Code compiles, passes relevant linter checks, and adheres to `protocols/code-quality-gate.md`.

---

## 5-Phase Commit Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                   PK:COMMIT LIFECYCLE                       │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Phase 1:     │ Phase 2:     │ Phase 3:     │ Phase 4:       │
│ Context      │ Atomic Group │ Conventional │ Developer      │
│ Preparation  │ & Staging    │ Message Spec │ Confirmation   │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

### Phase 1: Context Preparation

1. **Review Local Modifications**: Use `git diff` to review all current changes.
2. **Review Untracked Files**: Inspect untracked files (`??` in `git status -s`). Ensure scratch scripts or build output folders are added to `.gitignore` rather than accidentally committed.
3. **Quality Gate Verification (Evidence-Gated Oracle Gate)**: 
   - You MUST physically execute the project verification command matching the task ceremony tier (`fast` for Level 0, `fast` + `required` for Level 1, full tiers for Level 2/3) and observe `exit code 0` before staging.
   - **Bounded Retry & Escape Hatch**: If verification fails, apply a maximum of 2 automated repairs. If prerequisites are unavailable or the 3rd attempt fails, trigger the Escape Hatch: log the blocker with `> [!WARNING]` and HALT immediately without staging or committing.

### Controlled & Release-Critical Work Commit Gate

After the existing hygiene checks and before staging, Level 2 (Controlled) and Level 3 (Release-Critical) Work must pass this evidence gate linking `docs/tasks/<task-id>.md`. Level 0 (Direct) and Level 1 (Standard) work require clean Conventional Commit syntax and hygiene without mandatory Task Record links:

- Confirm the active `docs/tasks/<task-id>.md` Task Record exists, is in an editable state, and owns the current execution scope. `checkpoint_due`, `blocked`, `paused`, `handoff_ready`, and `aborted` tasks cannot proceed to commit.
- Confirm changed files remain within the recorded scope and every scope expansion has a linked Scope Change Record and required approval or separate Task Record.
- Confirm acceptance-criteria results, verification evidence, changed-file summary, blockers/resume condition, and review prerequisites are recorded. A commit link is not required before the first commit exists; it is added after the human-confirmed commit.
- Confirm the current revision and checkpoint/handoff state are consistent. A hard checkpoint blocks staging and commit actions until explicit resume evidence is recorded.
- Route commit construction, Conventional Commit formatting, staging, and developer confirmation through the rest of this workflow. A passing record or validator does not authorize `git add`, `git commit`, push, or any remote action.
- After the human confirms the commit, record the exact revision and commit evidence in the canonical Task Record. Validator success proves evidence consistency only; it does not approve the commit.

---

### Phase 2: Atomic Staging (One Concern Per Commit)

Senior Git history is **atomic**: each commit represents a single, complete, reversible logical change. Never bundle unrelated concerns into a single massive commit.

If a session touched multiple layers, propose splitting into sequential commits:

| Layer / Concern | Included Changes | Example Scope |
| :--- | :--- | :--- |
| **Data & Migrations** | Schema files, migrations, RLS policies, seed fixtures | `db`, `schema`, `migration` |
| **Backend & Contracts**| Server actions, endpoints, API contracts, domain services | `api`, `auth`, `server` |
| **Frontend & UI** | Components, hooks, design tokens, responsive styles | `ui`, `design`, `client` |
| **Testing & Fixtures** | Unit tests, Playwright specs, mock factories | `test`, `e2e` |
| **Infrastructure & CI**| GitHub Actions, Dockerfiles, package dependencies | `ci`, `deps`, `config` |
| **Documentation** | RFC specs, ADRs, post-mortems, README updates | `docs`, `adr`, `spec` |

**Staging Rule**:
Explicitly stage only the files relevant to the active atomic concern. Avoid blind `git add .` when multi-concern changes are present.

**Pre-Commit Secret & Hygiene Scan:**
Run the local harness preflight first: `bash <kit>/scripts/check-harness-security.sh <project>` (PowerShell: `pwsh -File <kit>/scripts/check-harness-security.ps1 -Root <project>`), resolving `<kit>` from `PROMPTKIT.md`. Review its redacted advisory findings; missing/incomplete checks are not a clean bill of health. See `docs/HARNESS-PREFLIGHT.md` in the kit. This working-tree scan does not replace the staged-index checks below.

Immediately after staging and before commit construction, perform a mandatory scan of the staged index for accidental secrets or debug probes (Time-of-Check to Time-of-Use safety):

1. **Staged Content Secret Scan**:
   Verify no embedded private keys, tokens, or credentials are staged for commit:
   ```bash
   git diff --cached | grep -E 'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{82}|sk_live_[0-9a-zA-Z]{24}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|password\s*[:=]\s*["'\''][^"'\'']{8,}["'\'']' || true
   ```
   If matching credential patterns are discovered in staged lines (`+`), halt immediately, alert the developer, and do not proceed with staging or committing.

2. **Suspicious Credential Filename Scan**:
   Verify no credential or environment files are staged or untracked (excluding safe templates like `.env.example`, `.env.template`, or `.env.dist`):
   ```bash
   git status -s | grep -vE '\.env\.(example|template|sample|dist|test)' | grep -E '\.env|\.pem$|\.key$|id_rsa|credentials\.json' || true
   ```
   If any secret files are modified, staged, or untracked, halt immediately and alert the developer to add them to `.gitignore`.

3. **Temporary Probe Purge**:
   Verify that temporary debug logs or probes (`[DEBUG-xxxx]`) from `pk:debug` are removed:
   ```bash
   git diff --cached | grep -E '\[DEBUG-|console\.log\("DEBUG|dbg!\(' || true
   ```
   If temporary probes remain in staged content, remove them before committing.

---

### Phase 3: Conventional Commit Specification (v1.0.0)

Format all commit messages strictly according to the Conventional Commits specification:

```text
<type>(<scope>): <imperative summary in lowercase, max 72 chars>

- <Context: Why was this change necessary?>
- <Mechanism: Key architectural decision or implementation detail>
- <Impact: Any side effects, schema shifts, or follow-ups required>

[BREAKING CHANGE: <explanation of breaking change and migration path>]
[Closes #<issue-number>]
```


#### Contract Impact Evidence or Maintenance Classification

Before developer confirmation, classify every PromptKit OS eligible commit using one of the two paths below. The classification may be recorded in the commit body or in a stable linked planning or review record. It provides traceability for later QA and release evaluation; it does not approve a version or release.

##### Public PromptKit Contract Impact

Use this path when the commit intentionally changes a user-observable PromptKit OS workflow, template, protocol, command trigger, documented output schema, required artifact, or documented behavior. Record all of the following in the commit body or linked record:

- **Evidence ID**: A stable evidence reference such as `EVIDENCE-YYYY-MM-DD-slug`.
- **Commit Evidence Location**: The commit-body field or linked planning/review record path and anchor containing this evidence.
- **Affected Public PromptKit Contract**: The workflow, template, protocol, trigger, output schema, required artifact, or behavior that changes.
- **User-Observable Before Behavior**: What a PromptKit OS user or maintainer observes before the change.
- **User-Observable After Behavior**: What the user or maintainer observes after the change.
- **Impact Classification**: `User-Facing Additive Contract Change`, `User-Facing Corrective Contract Change`, or `Breaking Contract Change`.
- **Proposed SemVer Candidate Impact**: `minor` for additive, `patch` for corrective, `major` for breaking with complete guidance, or `blocked` when required guidance is missing.
- **Impact Rationale**: Why the proposed impact follows the observable contract evidence.
- **Supporting Planning / Review Record**: The linked record when the evidence is not complete in the commit body, or `N/A` when the body is complete.
- **Migration and Upgrade Guidance**: For a breaking change, identify affected consumers, required consumer actions, and the supported transition path. Missing guidance is a release blocker. Use `N/A` only for non-breaking changes.

The Conventional Commit label is informational, not the versioning authority. A `feat`, `fix`, or `perf` label does not determine SemVer impact by itself. The evidence and later effective-range review determine the candidate.

##### Maintenance Commit

Use this path when the commit has no intentional Public PromptKit Contract change. Record an explicit declaration in the commit body or linked planning/review record:

- **Maintenance Commit**: `Yes`
- **No Intentional Public PromptKit Contract Change**: State this explicitly.
- **Maintenance Rationale**: Explain the documentation, test, refactor, style, chore, or internal evidence purpose.
- **Proposed SemVer Candidate Impact**: `none`
- **Supporting Planning / Review Record**: `[record path or N/A]`

A `docs`, `test`, `refactor`, `style`, or `chore` label does not silently establish the maintenance classification; the explicit declaration is required. A passing evidence check does not authorize staging, committing, pushing, merging, tagging, releasing, publishing, deploying, or rolling back.

---

#### Valid Commit Types:
* `feat`: New user-facing capability or API feature
* `fix`: Bug fix, defect resolution, or regression patch
* `refactor`: Structural rewrite that neither fixes a bug nor adds a feature
* `test`: Adding missing tests or correcting existing test suites
* `docs`: Documentation-only updates (ADRs, RFCs, READMEs)
* `perf`: Code change that improves runtime performance or reduces memory usage
* `style`: White-space, formatting, semicolon, or lint fixes (no production logic change)
* `chore`: Build tasks, package updates, configuration tweaks, or tooling maintenance

#### Summary Rules:
* Use the imperative, present tense: "add" not "added", "fix" not "fixing".
* No trailing period in the first line.
* Keep the first line under 72 characters.
* Always lowercase type and scope.

---

### Phase 4: High-Signal Commit Examples

#### Example 1: Database Migration with Invariant
```text
feat(data): add composite index and RLS policy for organization workspaces

- Add composite index on (org_id, created_at DESC) to speed up workspace queries
- Add Postgres RLS policy restricting workspace access to active organization members
- Scaffold migration file using Expand-Contract pattern
```

#### Example 2: Bug Fix with Root Cause Context
```text
fix(auth): handle expired OAuth refresh token race condition

- Wrap token refresh logic in a mutex lock to prevent concurrent token invalidation
- Add 5-second leeway buffer to token expiration validation
- Purge stale session cookies on refresh failure to force clean re-login

Closes #128
```

#### Example 3: Documentation and ADR
```text
docs(adrs): record decision to adopt UUIDv7 for primary keys

- Document performance benchmark against UUIDv4 in docs/adrs/0003-uuidv7.md
- Record trade-offs on B-tree index fragmentation and sequential sorting
```

---

### Phase 5: Developer Confirmation & Execution

1. Present the staged files and the complete proposed commit message to the developer.
2. If multiple concerns exist, explain the proposed commit sequence.
3. Upon developer confirmation, run the commit command:
   ```bash
   git add <staged-files>
   git commit -m "<subject>" -m "<body-paragraphs>"
   ```
4. Confirm commit creation with `git log -n 1 --stat`.
5. **Dual-Compatible Telemetry Status Card & Interactive Handoff**: Conclude the turn by displaying the status card and invoking the native interactive selection tool (skip the decorative card only when PROMPTKIT.md declares `status-cards: off`; halts still fire):
   > 📊 **Milestone**: `M2: Core Features` `[■■■■■□□□□□]` 42% (5/12)  
   > 🎯 **Active**: `TASK-04: Tenant CRUD` (Committed)  
   > 🟢 **Quality Gate**: Clean (`5/5 ACs ✓` · `🔒 7 Invariants`)

   > [!TIP]
   > ### 💡 Next Recommended Step
   > - If completing a task or milestone: run **`pk:checkpoint`** (compact session state & sync `docs/STATE.md`)
   > - If ready to open a pull request for review: run **`pk:pr`**
   > - If continuing work on the next issue: run **`pk:tasks`**

   *(You MUST invoke the host's native interactive selection tool e.g. `ask_question` / prompt picker as your final action with Option 1 marked `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`; Bounded to closed-set operational choices — for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead, see the Picker routing rule in `workflows/plan.md`)*


---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
