# Project Discovery Intake Protocol

## Purpose

Define a bounded, low-technical intake that establishes *what the human actually wants* before any architecture is proposed. It exists because an unbounded planning interview either interrogates the developer indefinitely or silently replaces unanswered questions with agent assumptions and agent-preferred complexity.

This protocol is loaded on demand. It is not part of the static directive.

---

## Activation

Run this protocol when **any** of the following is true:

- The repository is greenfield: no manifest, no source directory, no commit history describing shipped behavior.
- The project profile contains unresolved `[e.g. ...]` placeholders in the sections that describe the product, the stack, or the commands.
- The project profile has no `intake-status:` line and the project has no recorded planning record.

**Do not run this protocol** when:

- `intake-status: complete` is recorded and scope has not changed.
- The task is Level 0 (Direct) or Level 1 (Standard) work on an existing project.
- The human explicitly declines and accepts the recorded assumptions path (see §C).

Brownfield repositories with an existing filled profile and git history are **not** greenfield. A missing `intake-status:` line alone never triggers a full interview; it resolves to `legacy-partial`.

---

## A. Size Class and Question Budget

| Size | Signal | Rounds | Max questions | Extra artifacts |
| :--- | :--- | :--- | :--- | :--- |
| `small` | One surface, solo maintainer, short-lived tool or MVP | 1 | 5 | Intake Record only |
| `medium` | Two to three surfaces (for example web plus API, or API plus data) | 2 | 8 | Project design profile when a UI surface exists |
| `large` | Three or more surfaces, or authentication plus data plus deployment, or multiple teams | 3 | 12 | Architecture specification and Decision Records |

Rules:

1. The **human states the size**. The agent may suggest a size but must label it a suggestion and ask for confirmation.
2. Persist the confirmed value as `size: small | medium | large` in the project profile, using the same machine-readable convention as `profile:` and `tracking:`.
3. The budget is a **ceiling, not a target**. Stop as soon as the coverage slots in §B are satisfied. Never pad a round to reach the budget.
4. If the budget is exhausted with slots still open, close the intake and record the remaining slots as owned assumptions (§C).

### Round, Turn, and Question Counting

- A **turn** is one assistant message. A **round** is one complete pass over the unanswered slots, closed by the single "Anything to add?" invitation in §C.
- The `Rounds` column is a ceiling on rounds. The `Max questions` column is a ceiling on **total questions across the whole intake**, not per round.
- The per-turn band in §C bounds how many questions one message may carry; it never raises the total. When the remaining total is smaller than three, ask only what remains and close.
- Counts are asserted only when the Intake Record actually tracks them. If it does not record rounds used or questions asked, report `not tracked` and do not validate arithmetic against invented numbers.

---

## B. Coverage Slots

Walk these seven slots in order. Ask at most five questions per turn, in plain language, with technical terms second.

| # | Slot | The question being answered | Required? |
| :--- | :--- | :--- | :--- |
| 1 | Outcome and MVP floor | What is the smallest version that is genuinely useful? | Always |
| 2 | Users and success signal | Who benefits, and how will success be observed? | Always |
| 3 | Surfaces in scope | Which of UI, API, data store, background work, integrations are in scope? | Always |
| 4 | Deployment target | Where does this run: local only, managed platform, virtual server, or cloud? | Always |
| 5 | Existing artifacts | Do an architecture document, style guide, design system, specification, or tracker board already exist? Provide links or paths. | Always |
| 6 | Design inputs | If a UI surface is in scope: design-tool link, screenshots, token export, or an explicit decision to use agent defaults. | Only when slot 3 includes UI |
| 7 | Constraints | Required stack, deadline, budget, or compliance limits? | Always |

Slot guidance:

- Ask **outcome before technology**. Never open with a framework or hosting question.
- Slot 5 and slot 6 are **attachment-bearing slots**. Ask them in the context window (§D) so links, files, and screenshots can be provided.
- **Slot 6 Design Vibe**: If no external design link or screenshot is provided, offer the 4 curated aesthetic archetypes (`Warm Paper / Editorial`, `High-Density Fintech`, `Clean Modern SaaS`, `Dark Terminal`) or system defaults so the user selects their visual vibe upfront, avoiding an unstyled monochrome void.
- Accept "not sure yet" for any slot. Record it as an assumption with a proposed default rather than pressing for an answer.
- A slot answered earlier in the same project is never re-asked unless scope changed or new evidence invalidated it.

### Product-Shape Cover Questions (SaaS-Class Requests)

Some intents are **product-shaped**, not feature-shaped: the request implies accounts, per-user data, and money or third-party integrations — the SaaS shape. Slot 3 answers alone do not cover the decisions those surfaces create, so when slot 3 reports **two or more surfaces**, or the request names accounts plus data plus billing or integrations, ask these five **conditional** product-shape questions (`P1`–`P5`) in the same interview, in the context window (§D). They are an extension of slot 3 and slot 7 coverage, never five extra required slots.

| Q | Question being answered | Why it changes architecture | Boring default if unanswered |
| :--- | :--- | :--- | :--- |
| `P1` | Who can see whose data: one account, a shared workspace, or separate tenants? | Tenant boundary and every query behind it | Single-owner scope, no sharing |
| `P2` | How do people get in, and who administers them: self-serve signup, invitations, SSO, admin roles? | Auth surface and role model | Invitation-only, single admin |
| `P3` | Does money change hands — none, one-off, or recurring — and who is the billing source of truth? | Entitlements, webhooks, reconciliation | None in the MVP floor (Later ledger) |
| `P4` | What runs without a human: scheduled jobs, webhooks, notifications — and what happens after repeated failure? | Background surface and retry policy | Synchronous only, no jobs |
| `P5` | What constraints apply: personal data, region or residency, retention, audit expectations? | Data store, hosting region, logging | Recorded assumptions only, no compliance claims |

Rules:

1. **These are questions, not proposals.** Never answer them on the human's behalf; an unanswered slot becomes an owned `ASSUMPTION-*` record per §C, never a silent default.
2. **They extend slot 3 and slot 7 coverage instead of adding required slots** — one or two per round, inside the size-class cap (§A). If the budget is reached first, close the intake with assumptions (§C) instead of extending it.
3. **Never answer a product-shaped request with a stack, scaffold, generator, starter template, or `create-*` command.** Naming, choosing, installing, or announcing a technology during intake is a protocol violation: the intake's first output is questions, not files. Technology stays slot 7 and the accept-or-change proposals described above.
4. **A product-shaped request never authorizes an unattended build.** It states intent only; planning, milestones, and approvals still run through `pk:plan`, `pk:tasks`, and the milestone gate.
5. **Capabilities nobody asked for stay put.** Admin consoles, notification systems, and pricing tiers that do not trace to a stated requirement go to the Later ledger (§E.6), never into the MVP floor.

## C. Question Protocol and Stop Contract

### Round Shape

1. Ask **three to five** questions per turn. One question is acceptable when the previous answer changed the picture.
2. Acknowledge each accepted answer in a single line before moving on. Do not restate the whole conversation.
3. For any unanswered slot, propose a **boring default** and mark it as an assumption, never as a decision.

### The "Anything to Add?" Loop

Every round closes with exactly one open-ended invitation, asked in the context window:

> Anything to add — text, links, screenshots, or files? Or say "enough for now".

Repeat a new round only while a stop condition has not fired. Do not loop the invitation inside the same turn.

### Stop Conditions

Stop immediately when **any** of these is true:

1. All seven coverage slots are satisfied.
2. The human ends intake (accept "enough for now" without friction and without a counter-proposal).
3. A full round produces no new information.
4. The size-class question budget is reached.

### Close Contract

Close with a recorded Intake Record (§G) that includes:

- `close_reason: complete | human_stopped | no_new_info | budget_reached`
- The explicit list of slots that remain **unknown**, so "agreed for now" becomes an auditable fact rather than ambiguity
- One owned assumption record per unknown slot that affects architecture, with impact-if-wrong and a validation action

A closed-but-incomplete intake is a valid outcome. Refusing to proceed until every slot is answered is not.

### Attachment Handling

- If the host cannot read an attachment, say so plainly and ask for text, a quoted excerpt, or a pasted link. **Never guess the content of an unreadable attachment.**
- If an image or document is readable, restate in one line what was extracted (for example tokens, constraints, entity names) and confirm it before relying on it.
- Never request, echo, or store secrets. Continue to require `.env.example` with placeholder keys and a local `.env`.

---

## D. Interactive Picker Routing Rule

> Use a native modal picker **only** when all three conditions hold:
> 1. The option set is closed and has at most four entries.
> 2. The answer needs no attachment, no link, and no free text.
> 3. The agent has evidence-based grounds for the options, or the picker itself offers an explicit no-recommendation option.
>
> Otherwise ask in the **context window**.

Hard rules:

1. **Never** place an agent preference as Option 1 for an intent question. Intent questions include MVP scope, whether authentication is needed, tenancy model, target users, and deployment location. Intent belongs to the human; the agent asks and records it.
2. A picker must not be the only route to an answer that could legitimately include an attachment.
3. Picker-eligible decisions remain: profile selection, task tracker selection, ceremony level, planning depth, and equivalent closed-set operational choices.
4. Where a recommendation is genuinely evidence-based, state the evidence in one line inside the option label rather than relying on the "(Recommended)" marker alone.

## E. MVP Floor and Anti-Overengineering Gate

The gate exists because agent-proposed architecture is otherwise adopted by default. Apply it before any architecture, contract, or milestone is written.

1. **MVP floor first.** Architecture may only be proposed after slot 1 is answered in the human's own words. Quote the MVP floor back to the human before designing anything.
2. **Requirement trace.** Every proposed service, queue, cache, table, job, abstraction, or third-party dependency must cite a requirement the human stated. If it cannot cite one, it does not enter scope.
3. **Boring default plus upgrade path.** Choose the option with the fewest moving parts and state what would be added later if the project grows. Prefer the platform's built-in capability over a new dependency.
4. **Complexity budget.** Declare the moving-part count explicitly (services, tables, external dependencies). Exceeding the MVP floor requires explicit human approval, recorded with the reason.
5. **Defaults disclosure.** Emit a short list titled "Decisions I am defaulting for you" — for example default auth strategy, default hosting, default data store, default styling. The human accepts or changes each entry **before** architecture is written. This converts silent assumptions into a reviewable diff.
6. **Later ledger.** Anything genuinely useful but not required now is recorded as one line with a one-line cost estimate. Agent-proposed features never enter milestones automatically.
7. **Scale-independence.** These rules apply at every size class. A `large` project may have more parts, but each part still requires a stated requirement and explicit approval.

---

## F. Mid-Implementation Delta Path

Information often arrives after planning or during implementation. Classify it, record it, then continue.

| Delta type | Action | Record |
| :--- | :--- | :--- |
| Documentation, configuration, or wording only, no behavior change | Apply and continue | `docs/STATE.md` session log |
| Changes scope, acceptance criteria, or in-scope files | Require a Scope Change Record before continuing, then re-run the affected planning depth | Task Record update and planning record |
| Changes architecture, data ownership, contracts, authentication, or deployment | **Block execution** and re-open planning at the correct depth | Planning record revision and assumption reconciliation |
| New idea not needed now | Record one line | Later ledger in the Intake Record |

Rules:

1. **Never absorb a delta silently.** An unrecorded change is a defect in the process, not a convenience.
2. **Interception**: when `pk:sync` or `pk:checkpoint` observes requirements in the session that are not recorded anywhere, classify and record them before work continues.
3. **Proportional ceremony**: a typo-level clarification must not create scope-change paperwork; anything touching behavior, contracts, or data must not bypass it.
4. Authority is unchanged: the canonical Task Record remains authoritative for execution, and `docs/STATE.md` remains a projection owned by `pk:checkpoint`.

---

## G. Artifacts and Authority

### Intake Record

Write `docs/specs/YYYY-MM-DD-intake-<project>.md` using the existing specification path so no new directory or installer change is required. It contains:

- **Size class** and the confirmed value of `size:`
- **Seven-slot coverage table** with each slot marked answered, assumed, or unknown
- **Attachments and links received** (paths or URLs), plus anything the host could not read
- **Decisions I am defaulting for you**, each marked accepted or changed
- **Later ledger**
- **`close_reason`** and the explicit unknown list
- **Assumption records** for unknown slots that affect architecture, using the existing `ASSUMPTION-*` convention with owners and validation actions
- **Host Documentation Divergence** rows for every detected pre-existing project document statement that contradicts a confirmed decision (see *Host Documentation Divergence* below)

#### Host Documentation Divergence

A detected pre-existing project document (`ARCHITECTURE.md`, `ROADMAP.md`, `RUNBOOK.md`/`OPERATIONS.md`, `STYLE.md`/`STYLEGUIDE.md`) sometimes states what a confirmed intake decision contradicts. The Intake Record owns one divergence row per contradiction. It is the only registry: no second ledger is created, and `docs/STATE.md` never becomes a competing source of truth.

| Field | Required value |
| :--- | :--- |
| **Divergence ID** | `DIVERGENCE-<spec-slug>-<nnn>` - one stable ID per contradiction |
| **Document** | Project-relative path of the contradicted document, exactly as it was read |
| **Line** | One-based line number of the contradicted statement inside that document |
| **Decision ID** | The `DECISION-<spec-slug>-<nnn>` that contradicts it |
| **Precedence** | Exactly one of `host-doc-authority`, `decision-authority`, `unresolved` |
| **Designated By** | `not designated`, or the designating human, the date, and the record path |
| **Owner** | The named person or role accountable for resolving the contradiction |
| **Next Action** | The concrete next step that closes it |

The Intake Record stores these rows as one Markdown table with exactly these eight columns, in this order: `Divergence ID`, `Document`, `Line`, `Decision ID`, `Precedence`, `Designated By`, `Owner`, `Next Action`.

Precedence is never implied:

- `unresolved` is the default and the only value an agent may assign. A confirmed decision is not by itself evidence that a statement in an existing project document has been superseded; the `DIVERGENCE-*` row stays `unresolved` until a human designates it.
- `host-doc-authority` and `decision-authority` may be recorded only from an explicit human designation captured in this Intake Record, naming the approver, the date, and the record path.
- One contradiction produces exactly one row. A second row for the same document, line, and decision is a duplicate, not a second conflict.

Rules:

1. **Host documents are immutable.** Onboarding records the contradiction; it never rewrites, reformats, normalizes, or otherwise edits a pre-existing project document. Resolution happens in the document that owns the statement, under separate human authorization.
2. **Every precedence claim is traceable.** A precedence statement in `PROMPTKIT.md`, `DESIGN.md`, or `docs/STATE.md` cites its `DIVERGENCE-*` row, its `DECISION-*` ID, an explicit policy path, or the Intake Record path. An unsupported override claim is not policy and must not be emitted.
3. **The divergence record does not re-decide architecture.** The Intake Record owns the interview answers, the unknown list, and these rows; it does not silently revise what a project document already states.
4. **Residual risk stays owned.** An unresolved row keeps its owner and next action in the Intake Record. Onboarding does not widen its `docs/STATE.md` write envelope to Section 5; a later `pk:checkpoint` or `pk:tasks` run may re-home the open question there under the State Mutation Contract.

### Authority Model

| Artifact | Owns |
| :--- | :--- |
| Intake Record | The interview answers and the unknown list |
| Project profile (`PROMPTKIT.md`) | The derived projection of those answers (`size:`, `intake-status:`, `intake-record:`, stack, commands) |
| Planning record (`docs/specs/`) | Architecture, contracts, migration, failure modes, and milestones |
| Task Record (`docs/tasks/`) | Execution authority: scope, acceptance criteria, state, and approval |
| `docs/STATE.md` | Execution projection owned by `pk:checkpoint` |

No new authority is created and no second task database is introduced.

`intake-record:` is a project-relative path reference to the Intake Record under `docs/specs/` by convention — it makes that record discoverable; it is not a second source of interview or decision authority. The Intake Record it names remains the owner of the interview answers and the unknown list. `pk:doctor` verifies the reference only when `intake-status:` is `complete`: an absent or placeholder line is a non-fatal compatibility advisory, while a line that does not resolve to a readable project-relative file inside the project root is reported as `INCOMPLETE` or `MISSING` (exit 1). A missing line is valid for profiles created before this field existed; a completed intake should reference an existing record. Never guess this value.

### Artifact Provenance Contract

The four onboarding artifacts — the Intake Record, `PROMPTKIT.md`, `DESIGN.md`, and `docs/STATE.md` — must keep authority categories distinguishable. Every statement that claims authority carries exactly one class:

| Class | Minimum evidence | May be described as |
| :--- | :--- | :--- |
| **human-confirmed decision** | A stable `DECISION-<spec-slug>-<nnn>` ID, or an explicit reference to pre-existing documented policy | agreed, approved, locked — only with that evidence |
| **accepted default** | The exact accepted value and its bounded scope; adjacent choices stay open | accepted for this scope |
| **agent-owned assumption** | `ASSUMPTION-<spec-slug>-<nnn>`, named owner, and validation action | provisional |
| **derived PromptKit baseline** | No human approval; marked `Source: derived PromptKit baseline` | PromptKit baseline |
| **pending verification obligation** | Named owner, status, and tracking destination | unverified |
| **resolved or superseded assumption** | Successor `DECISION-*`/`ASSUMPTION-*` link plus the residual operational risk it leaves behind | resolved, superseded |

Rules:

1. **No implied promotion.** A template default, a checklist item, repeated use, or an agent recommendation is never human-approved by position. Memory-to-policy promotion follows `protocols/context-sync.md` §3.1; this contract adds no second promotion path.
2. **Traceable locks.** `docs/STATE.md` §4 and any "locked" or "human-approved" statement in `PROMPTKIT.md` or `DESIGN.md` cites a `DECISION-*` ID or an explicit policy path. Untraceable recommendations stay candidates.
3. **Bounded defaults.** Accepting one default resolves only that decision. It never settles an adjacent decision — accepting a disposable database container does not choose a test runner or a managed vendor.
4. **Assumption lifecycle.** When a confirmed decision answers an assumption's unanswered decision, mark the assumption `superseded` (or `accepted` when the decision adopts the provisional answer) and record the decision link. Do not delete the assumption and do not leave it listed as open.
5. **Residual operational risk survives resolution.** Resolution retires the unknown, not the risk. Re-home residual operational risk to `docs/STATE.md` §5 (Known Blockers, Risks & Open Questions) or to a pending verification obligation before closing the assumption.
6. **Obligations stay owned and tracked.** Every pending verification obligation names an owner, a status, and a destination (`docs/STATE.md` §5/§7 or a Task Record). An obligation missing any of the three is untracked.
7. **No arithmetic without a count.** Question and round counts are asserted only when the Intake Record records them (§A).
8. **Precedence is designated, never implied.** A statement that asserts how a pre-existing project document relates to a confirmed decision carries a precedence designation and its source (a `DIVERGENCE-*` row, a `DECISION-*` ID, an explicit policy path, or the Intake Record path). A confirmed decision alone never supersedes a document statement.

### Human-review checklist

Static checks cannot establish intent, authority, or adequacy. Before declaring greenfield onboarding complete, the reviewer confirms:

- [ ] Every locked or human-approved invariant cites a `DECISION-*` ID or an explicit policy.
- [ ] No assumption remains listed as open after the decision that answered it was confirmed.
- [ ] Each resolved assumption's residual operational risk is still visible in §5 or in an obligation.
- [ ] Human decisions, agent assumptions, accepted defaults, and derived baselines are labelled, not blended.
- [ ] Each accepted default states its exact scope and has not resolved adjacent choices.
- [ ] Every pending verification obligation has an owner, a status, and a destination.
- [ ] Derived PromptKit baselines in `PROMPTKIT.md` §7 are still marked derived, not approved.
- [ ] Every host-document divergence row names its document, line, decision, precedence, designation, owner, and next action, and no generated artifact states a precedence claim without a source reference.

These checks are manual by design. A green static suite does not prove live-agent compliance.

---

## H. Relationship to Other Workflows

- **`pk:onboard`** runs this protocol as Phase 0 for greenfield repositories, and continues to use passive discovery for brownfield repositories.
- **`pk:plan`** runs a Step 0 preflight that reads intake state: `complete` proceeds unchanged, `incomplete` runs the bounded intake or routes to `pk:onboard`.
- **`pk:design`** consumes slot 6 outputs (design-tool links, screenshots, token exports) instead of reverse-engineering visual intent later.
- **`pk:sync`** and **`pk:checkpoint`** apply the §F interception rule.
- **`pk:tasks`** consumes the MVP floor and Later ledger boundary, so deferred items are not decomposed into implementation work.

---

## Completion Criteria

- Size class confirmed and persisted as `size:`.
- Seven-slot coverage recorded, including marked unknowns.
- `close_reason` recorded, with assumptions owned for unknown architecture-affecting slots.
- No `[e.g. ...]` placeholder remains in the profile sections the intake answered.
- MVP floor stated in the human's words, requirement trace satisfied, defaults disclosed and accepted or changed.