# Workflow and template audit

<a id="REVIEW-2026-09-30-workflow-template-audit"></a>

- **Review ID**: REVIEW-2026-09-30-workflow-template-audit
- **Status**: complete
- **Reviewed revision**: c41103ee9d17a388a5a8e049d572f1abbfd24e30 (GitHub main, 30 September 2026)
- **Review mode**: Full-document audit at a fixed revision; no diff baseline was requested.
- **Outcome**: Corrections recommended. One high-priority security example and thirteen medium-priority command or contract defects.
- **Execution limitation**: Local process creation failed with OS error 2. This is source inspection, reference-tree checking, official documentation verification, and color-contrast arithmetic, not executed installer, auth, UI, or test-suite QA.
- **Changes**: Only this review artifact and its ledger were written. No implementation files or external comments were changed.

## Scope and coverage

Reviewed all requested documents: workflows/sync.md, workflows/auth.md, workflows/checkpoint.md, workflows/pr.md, workflows/design-system.md, templates/code-review-checklist.md, templates/adr-template.md, templates/release-evaluation-template.md, templates/contract-impact-evidence-template.md, templates/design-tokens-spec.md, templates/design-profile-template.md, templates/test-plan-template.md. The typo checkpoint,md was resolved to checkpoint.md. Root pr.md and auth.md do not exist at this revision; their workflow files were reviewed.

Related sources inspected where needed: auth-session recipe, auth matrix, context-sync, quality gate, telemetry protocol, route/test/review workflows, internal release procedure and approved release record. Explicit non-placeholder Markdown file links in the requested documents resolve against the exact-revision tree. This does not verify symbolic placeholders or external link availability.

## Findings

### 1. [P1] Make refresh-token consumption atomic

[docs/recipes/auth-session.md:91](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/docs/recipes/auth-session.md#L91-L101)

The canonical recipe reads `used`, marks the token used, and creates its successor in separate operations. Two concurrent exchanges can both read `used=false` and issue valid successors without entering reuse detection. This violates the recipe's single-use contract.

**Suggested correction:** Consume the token conditionally and create the successor in one transaction or equivalent atomic store operation; a failed consumption must take the reuse/revocation path.

### 2. [P2] Remove unsupported PR creation flags

[workflows/pr.md:117](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/pr.md#L117-L121)

Both ordinary and draft creation examples pass `--json url --jq .url` to `gh pr create`. These flags are absent from the official create command; the examples fail before creating the PR.

**Suggested correction:** Remove the unsupported flags and capture the command's URL output, or query afterward with `gh pr view --json url --jq .url`.

### 3. [P2] Correct cookie security guarantees

[workflows/auth.md:34](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/auth.md#L34-L36)

The example labels HttpOnly 'XSS immune' and says SameSite=Lax protects top-level navigations. HttpOnly blocks script access to the cookie, but injected scripts can still send authenticated requests. Lax permits cross-site top-level safe-method navigations. The linked recipe's independent CSRF checks are stronger than these misleading comments.

**Suggested correction:** Describe the narrower guarantees accurately and explicitly carry the recipe's CSRF checks into the auth strategy.

### 4. [P2] Replace the failing contrast pairs

[templates/design-tokens-spec.md:74](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/templates/design-tokens-spec.md#L74-L97)

The dark palette claims contrast verified at least 4.5:1. White on #6366f1 is 4.4669:1; white on #f43f5e is 3.6718:1. Light muted #64748b on #f1f5f9 at lines 63–64 is 4.3439:1. All fail normal-text AA, so copying the supposedly verified tokens can produce inaccessible labels.

**Suggested correction:** Change the foreground/background pairs to meet the stated normal-text threshold and document the actual checked pairs.

### 5. [P2] Apply reduced-motion rules to the example

[templates/design-tokens-spec.md:297](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/templates/design-tokens-spec.md#L297-L298)

The dialog uses hardcoded `duration-200` and animate-in/out utilities. The fallback at lines 266–271 changes only --transition-* variables, which this component never consumes. A consumer copying this reference still animates under reduced-motion preference.

**Suggested correction:** Add effective reduced-motion rules for both transitions and animations, or wire the component to the defined tokens and disable animations separately.

### 6. [P2] Scope design completion by tier and stack

[workflows/design-system.md:346](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/design-system.md#L346-L355)

D0 at line 107 explicitly needs no tokens artifact beyond a target-file note, but Step 8 and completion require an artifact and the full delivery gate without exceptions. The gate also unconditionally requires React-specific rendering rules at line 390 despite the stack-neutral contract at line 13. D0 changes and non-React surfaces therefore cannot satisfy the literal completion rules.

**Suggested correction:** Apply artifact and gate requirements according to D0–D3; accept the D0 note and mark React-specific gate items not applicable for other stacks.

### 7. [P2] Use the latest approved candidate as the release baseline

[docs/internal/release-evaluation.md:17](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/docs/internal/release-evaluation.md#L17-L17)

The procedure selects the latest approved record's Prior Approved Release Commit. The template at line 34 correctly selects its candidate commit; the latest v1.9.2 approved record exposes Approved Release Candidate Commit at line 8 and has no Prior field. Literal execution either blocks selection or includes already released changes again.

**Suggested correction:** Read Approved Release Candidate Commit from the latest complete approved record and store it as the new evaluation's Prior Approved Release Commit.

### 8. [P2] Respect telemetry opt-out during sync

[workflows/sync.md:79](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/sync.md#L79-L85)

Sync requires a status card unconditionally and treats missing cards as drift at line 13. protocols/telemetry-cards.md:162 explicitly suppresses decorative cards when status-cards: off. Sync can undo the configured quiet behavior.

**Suggested correction:** Qualify card emission and drift detection with the status-cards setting; genuine halts remain visible.

### 9. [P2] Resolve conflicting profile mutation instructions

[workflows/sync.md:108](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/sync.md#L108-L108)

The interception table tells the agent to append documentation-only deltas to PROMPTKIT.md and continue. Line 35 permits only tracking backfill as a mutation, and line 70 requires developer confirmation before profile patches. The same request therefore has conflicting write authority.

**Suggested correction:** Persist the intake entry and propose the profile patch; define precisely when an explicit user instruction authorizes application and retain confirmation for inferred changes.

### 10. [P2] Preserve unrelated working-set state after merge

[workflows/checkpoint.md:245](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/checkpoint.md#L245-L260)

Any merged-PR notification triggers a task completion and reset of STATE Section 3 without matching the merged task to active ownership. If task A merges while task B occupies the working set, this clears B's continuity data. Controlled-work completion also updates only STATE even though the Task Record is authoritative at lines 78 and 90.

**Suggested correction:** Identify the merged task, reconcile its canonical completion evidence, and update only its projection while preserving unrelated working-set entries. Check workspace state before switching branches.

### 11. [P2] Accept artifact-appropriate PR verification consistently

[workflows/pr.md:47](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/pr.md#L47-L47)

The precondition at line 14 accepts artifact-appropriate checks, but line 47 requires tests/typecheck and line 101 demands a test command plus exit 0 beside each checked AC. A documentation validator or artifact inspection accepted initially is excluded later by the literal evidence list.

**Suggested correction:** Use the applicable verification command or observation and its result consistently, including documentation checks; keep claims tied to current evidence.

### 12. [P2] Keep tests-first conditional on enabled TDD

[workflows/test.md:205](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/test.md#L205-L205)

This anti-pattern remedy always requires a RED test before implementation. Lines 155 and 219 explicitly allow disabled TDD, matching the test-plan template. The unconditional remedy reintroduces tests-first sequencing for disabled mode.

**Suggested correction:** Qualify the RED-before-implementation rule with the canonical Task Record's enabled TDD mode.

### 13. [P2] Provide the claims that the verifier must audit

[workflows/review.md:299](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/workflows/review.md#L299-L308)

The verifier receives only ACs, a diff, and runner commands, but must audit every Task Record and PR-body claim against recorded exit codes. The claims and their recorded execution evidence are omitted from the strictly bounded briefing.

**Suggested correction:** Include bounded claim excerpts, record references and verification evidence in the permitted briefing, or narrow the audit duty to supplied inputs.

### 14. [P2] Make endpoint checks depend on the access contract

[templates/code-review-checklist.md:47](https://github.com/lowqualityloey/promptkit-os/blob/c41103ee9d17a388a5a8e049d572f1abbfd24e30/templates/code-review-checklist.md#L47-L47)

The checklist requires a user session and permissions on every endpoint. Public login, registration and password-recovery routes explicitly discussed by the auth workflow cannot require an existing authenticated session. Service endpoints may have a different credential model.

**Suggested correction:** Require authentication and authorization appropriate to protected endpoints, and explicitly review the declared public/service access contract for the others.

## Secondary clarification

The design workflow accepts text-only controls at line 368 and the design profile accepts text-only navigation at line 14, yet the delivery checklist requires an icon family across all interactive controls at line 380. Clarify that family consistency applies to icons that exist; it should not require adding icons to approved text-only controls.

No additional concrete blockers were established in the ADR, release-evaluation, contract-impact-evidence or test-plan templates themselves. The latter three correctly preserve their canonical authority boundaries; the findings above identify contradictions in their consumers. The design profile's placeholder-resolution check is useful and should be retained.

## External verification sources

- [GitHub CLI create manual](https://cli.github.com/manual/gh_pr_create): supported create options and URL output.
- [OWASP session management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html): HttpOnly and SameSite behavior.
- [OWASP CSRF prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html): independent mutation protections.
- [W3C contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html): 4.5:1 normal-text threshold, with no rounding up.

## Review lanes

All lanes reviewed c41103ee9d17a388a5a8e049d572f1abbfd24e30; terminal execution was unavailable to every lane.

| Lane | Verdict | Report source |
| --- | --- | --- |
| Code quality / design | FAIL | doc_design final report |
| Context mining | FAIL | doc_context final report |
| Goal / contracts | FAIL | doc_contracts final report |
| Source QA | FAIL | doc_qa final report |
| Security | FAIL | doc_security final report |

Root reconciled overlapping findings and omitted the checkpoint remote-operation claim because the cited prohibition occurs inside a release-specific handoff fragment. No separate runtime pass is claimed. No Simplification Candidates found beyond the explicit consistency corrections above.

