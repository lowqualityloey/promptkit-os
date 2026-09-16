# Pull Request Preparation Workflow

## Fast Shorthand
Trigger anytime with: `pk:pr` (or `/pk-pr`)

## Mission
Transform a series of local commits into a high-signal, staff-level Pull Request description. Compile testing evidence, evaluate database migration safety, document rollback procedures, and optionally automate PR creation via the GitHub CLI (`gh pr create`).

---

## Preconditions
- Active feature or bugfix branch with commits ready for review.
- Target base branch identified (default: `main` or `origin/main`).
- All tests and typechecks passing per `protocols/code-quality-gate.md`.

---

## 4-Phase Pull Request Protocol

```text
┌─────────────────────────────────────────────────────────────┐
│                      PK:PR LIFECYCLE                        │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Phase 1:     │ Phase 2:     │ Phase 3:     │ Phase 4:       │
│ Diff & Log   │ Evidence &   │ PR Body      │ Submission or  │
│ Inspection   │ Safety Audit │ Generation   │ CLI Creation   │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

### Phase 1: Diff & Log Inspection

1. **Verify Target Comparison**:
    ```bash
    BASE_BRANCH="origin/main"
    git log ${BASE_BRANCH}..HEAD --oneline
    git diff --stat ${BASE_BRANCH}...HEAD
    ```
2. **Pre-PR Conflict & Gate Check (Mandatory)**:
    ```bash
    git status -s
    git fetch origin && git log HEAD..origin/main --oneline
    ```
    - If the tree is dirty with this task's uncommitted changes, stop: stage via `pk:commit` first (milestone git boundary).
    - If `origin/main` advanced (log shows commits), rebase or merge before opening the PR; never push a known-conflicted branch.
    - Require `Quality Gate: measured this turn` (tests/typecheck actually run) before `gh pr create`. Otherwise record `not measured` and do not open the PR.
    - On conflict or dirty tree, emit `> [!WARNING]` titled `### ⚠️ Blocked: Waiting on Human Input` with exact resolve commands. No auto-push; human approval boundary holds.
2. **Review Commit History**:
   Ensure commits on the branch follow Conventional Commits format (`feat:`, `fix:`, `refactor:`, `test:`). If commits are messy, suggest cleaning them up via `pk:commit` before opening the PR.

---

### Phase 2: Evidence & Safety Audit

Before writing the PR body, collect verifiable evidence:

1. **Test Verification**:
   Execute the project test suite and capture the result:
   ```bash
   pnpm test        # or npm test / pytest
   pnpm test:e2e    # if E2E suites exist
   ```
2. **Database Migration Safety**:
   Inspect whether any migration files were touched:
   - Are schema changes additive (Expand-Contract pattern)?
   - Are there any `DROP TABLE`, `DROP COLUMN`, or `TRUNCATE` calls? If so, halt and require multi-phase migration planning.
   - Are Row-Level Security (RLS) policies and composite indexes defined?
3. **Secret & Probe Check**:
   Confirm that zero secrets or temporary debug probes (`[DEBUG-xxxx]`) exist across the branch diff.

### Controlled & Release-Critical Work PR Gate

Before generating a PR body for Level 2 (Controlled) or Level 3 (Release-Critical) Work, include and verify:

- **Task Identity**: Task ID, canonical `docs/tasks/<task-id>.md` path, specification, execution scope, and current state (normally `awaiting_review`).
- **Scope and Acceptance**: Changed-file summary, stable `AC-*` results, verification commands/results, review findings, blockers, and linked Scope Change or Exception Records.
- **Revision and Handoff Evidence**: Branch, exact revision, latest checkpoint/handoff links, and evidence that the working tree matches the reviewed scope.
- **CI and Completion Evidence**: CI provider/workflow/job/run references, validator results when available, commit evidence, and the required completion or milestone decision.
- **Risk and Rollback**: Preserve the existing migration safety, risk, and rollback requirements. Do not smuggle scope expansion into the PR body; record it first.

A consistent Task Record or validator result proves durable evidence consistency only. It does not approve opening or merging a remote pull request. Preserve the optional `gh pr create` path in Phase 4, but require explicit developer approval before executing it.

---

### Execution-Control PR Evidence Template

For Level 2 (Controlled) and Level 3 (Release-Critical) Work, use the optional **Execution-Control Traceability** section in `templates/pull-request-template.md` to link the Task ID and canonical record, `awaiting_review` state, acceptance results, exact revision, checkpoint/handoff, CI, blockers, scope changes, and exceptions. For Level 0 (Direct) and Level 1 (Standard) Work, record `N/A`. Keep `gh pr create` optional and explicitly developer-approved; a passing validator or CI job supports traceability only and does not approve opening, merging, shipping, or deploying the PR.

---

### Phase 3: PR Body Generation

Structure the PR description using `templates/pull-request-template.md`:

1. **Title**: Follow Conventional Commits format (`type(scope): concise summary under 72 chars`).
2. **Summary**: Group changes by architectural layer (Data, Backend, Frontend, Config).
3. **Acceptance Criteria Checklist**: Include a mandatory `### Acceptance Criteria Checklist` section containing verified Gherkin scenarios:
   ```markdown
   ### Acceptance Criteria Checklist
   - [x] **AC-1**: [Given / When / Then scenario]
   - [x] **AC-2**: [Given / When / Then scenario]
   ```
4. **Database Checklist**: State whether migrations are present and verify Expand-Contract safety.
5. **Testing Evidence**: Paste test runner pass counts and provide numbered manual testing steps.
6. **Rollback Strategy**: Document whether this PR is zero-state reversible or requires step-by-step database rollbacks.
7. **Reviewer Focus**: Point reviewers to the most load-bearing lines or complex logic.

---

### Phase 4: Submission, CLI Creation & Handoff Boundary

Provide the generated PR description to the developer in two formats:

1. **Markdown Document**: For copy-pasting directly into GitHub, GitLab, or Bitbucket web interfaces.
2. **GitHub CLI Command (`gh pr create`)**:
    Offer a pre-formatted CLI command to open the PR immediately:
    ```bash
    gh pr create --title "<type>(<scope>): <summary>" --body-file pr-body.md --json url --jq .url
    ```
    Capture the returned URL (or `gh pr view --json url --jq .url` for MCP-created PRs). If no URL is available, write `PR URL: not measured — paste link from browser`. Never invent a URL.
    *(Or interactive `gh pr create --web`)*.

### PR Link Callout (Dual-Compatible)

Upon presenting or opening the PR, close with an attention callout (not TIP — action required). Dual-compatible: `> [!IMPORTANT]` + `> ` prefix only, standard markdown link (clickable in IDE, selectable in CLI), zero HTML:

```markdown
> [!IMPORTANT]
> ### 🛑 Action Required From You: Review PR #<number>
> **PR:** [#<number> — <title>](<url>)
> - Files: <url>/files · Checks: <url>/checks
> - Merge (after green): `gh pr merge <number> --squash --delete-branch`
```

### Human Authority & Merge Boundary
The AI assistant drafts the pull request and compiles verification evidence, but the human engineer retains sole authority over code review, approval, and merging to `main`. The AI assistant must **never** execute `git push origin main` or merge pull requests directly without explicit developer authorization.

Upon presenting or opening the PR, conclude with the standard Telemetry Status Card and invoke the native interactive selection tool (skip the decorative card only when PROMPTKIT.md declares `status-cards: off`; halts still fire):
> 📊 **Milestone**: `M2: Core Features` `[■■■■■□□□□□]` 50% (6/12)  
> 🎯 **Active**: PR `#<number>` (`<head-branch> → main`)  
> 🟢 **Quality Gate**: Clean (`<passed>/<total> CI Passing ✓` · `🔒 <n> Invariants Intact`)

> [!TIP]
> ### 💡 Next Recommended Step
> - **To Merge**: Run **`gh pr merge <number> --squash --delete-branch`** (or review on GitHub)
> - **Next Task**: Run **`pk:plan TASK-XX`** or **`pk:checkpoint`**

*(You MUST invoke the host's native interactive selection tool e.g. `ask_question` / prompt picker as your final action with Option 1 marked `(Recommended)` so the developer can navigate with arrow keys and confirm with `Enter`; Bounded to closed-set operational choices — for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead, see the Picker routing rule in `workflows/plan.md`)*
