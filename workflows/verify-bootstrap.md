# Verify-Bootstrap Workflow (Project-Local Verification Surface)

## Fast Shorthand
Trigger anytime with: `pk:verify-bootstrap`

## Mission
Generate a project-local verification surface so done-gates have something real to gate against. In greenfield installs — where no test infrastructure exists — the Bounded Oracle (`protocols/code-quality-gate.md` §5) degrades to prose. This workflow scaffolds deterministic, re-runnable behavior checks (`verify/` + verification map), demonstrates one deliberate red/green cycle during bootstrap, and wires `pk:ship` / `pk:fix` / `pk:review` gates to prefer this surface as the done-gate target when present.

## Level
**Level 2 — Controlled.** Cross-gate contract surface; requires a canonical Task Record (`docs/tasks/<id>.md`) before implementation. Generation writes host-executable files and therefore requires explicit human confirmation per the guardrail below.

## Non-Overlap (ADR 0002 Gate Record)
- `workflows/test.md` plans pyramid seams for existing code; it has no greenfield interview, no artifact-generation procedure, and no drift-maintenance cadence.
- `workflows/onboard.md` Phase 4 catalogues missing seams but is passive discovery plus human-authorized generation of PromptKit-managed artifacts only (`PROMPTKIT.md`, `DESIGN.md`, `docs/STATE.md`).
- `workflows/plan.md` produces specs, not runnable checks.
- `docs/recipes/test-isolation.md` codifies portable boundary contracts; this needs an interview procedure, gate wiring, and drift maintenance — workflow-shaped, not recipe-shaped.

## Non-Negotiable Guardrail: Human-Authorized Generation
Phases 1–2 are passive discovery (manifests, runners, existing checks). Phase 3+ generates host-executable files (`verify/` scripts, verification map) **only after explicit human confirmation** following the findings summary. Host application source and configuration remain untouched without authorization, per `workflows/onboard.md` Non-Negotiable Guardrail. The operator interview follows Decision Contract rules (Type-B, budgeted): 3–7 behaviors that would prove the app works — happy paths and kill-switches.

---

## Preconditions
- Task Record exists at `docs/tasks/<id>.md` (Level 2).
- Operator available for the budgeted interview (greenfield) or suite inventory walkthrough (brownfield).

---

## 4-Phase Bootstrap Protocol

```text
┌──────────────────────────────────────────────────────────────┐
│                 PK:VERIFY-BOOTSTRAP LIFECYCLE                │
├──────────────┬──────────────┬───────────────┬────────────────┤
│ Phase 1:     │ Phase 2:     │ Phase 3:      │ Phase 4:       │
│ Inventory    │ Interview    │ Generate &    │ Wire &         │
│              │              │ Red/Green     │ Maintain       │
└──────────────┴──────────────┴───────────────┴────────────────┘
```

### Phase 1: Inventory what "verified" means here
1. Detect manifests, test runners, and existing checks (read-only).
2. Brownfield: catalogue existing suites — generated checks **incorporate, never replace** them.
3. Greenfield (zero tests): record `N/A - no existing suite` and proceed to interview.

### Phase 2: Interview (Type-B, budgeted)
1. Ask the operator for the 3–7 behaviors that prove the app works.
2. Record each as Given/When/Then in the Task Record.
3. Confirm the `verify/` path and runner in the host profile before generating.

### Phase 3: Generate + demonstrate red/green (owner: bootstrap executor)
1. Generate `verify/` + verification map: deterministic, re-runnable scripts or commands per behavior — language-appropriate, no new framework dependencies, exit-code-0 addressable.
2. **Mechanized red test (#230 guard applied):** deliberately break one behavior, observe the corresponding check exit non-zero, restore, observe exit 0. Record break procedure + both exit codes as evidence.
3. **Halt-not-waive:** if red cannot be produced, HALT with the canonical `> [!WARNING]` `### 🚫BLOCKED:` callout per `protocols/telemetry-cards.md` — never waive the guard.

### Phase 4: Wire into the existing contract + drift maintenance
1. Record the verification surface as the preferred done-gate target for `pk:ship` / `pk:fix` / `pk:review` in the host profile.
2. Generated checks count as executed evidence under existing oracle rules (exit code 0 required; max 2 auto-repair attempts).
3. **Drift maintenance:** re-walk the feature map against the codebase on retrofit cadence so the surface tracks the app instead of rotting.

---

## Completion Criteria
- [ ] Project-local verification artifact exists with ≥3 deterministic behavior checks.
- [ ] One deliberate red/green cycle demonstrated with recorded evidence (break procedure, non-zero exit, restored zero exit).
- [ ] Existing suites incorporated, never replaced (or `N/A - no existing suite` recorded).
- [ ] Host profile records the surface as the preferred done-gate target.
- [ ] Dual-Compatible Telemetry Status Card emitted per protocol.

## Related References
- Oracle contract: [`protocols/code-quality-gate.md`](../protocols/code-quality-gate.md) §5.
- Host-write authority: [`workflows/onboard.md`](onboard.md) Non-Negotiable Guardrail.
- Host profile template: [`templates/project-profile-template.md`](../templates/project-profile-template.md).
