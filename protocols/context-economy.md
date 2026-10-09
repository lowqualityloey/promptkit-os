# Context Economy & Progressive Zoom Protocol

This document establishes the canonical **Context Economy & Progressive Zoom Protocol** for PromptKit OS. It defines how AI coding agents within PromptKit acquire, validate, and constrain the context they consume, ensuring maximum safety and accuracy without wasting token budgets or causing information starvation.

> **Enforcement boundary — read this first.** This protocol is an **advisory agent instruction**, not a runtime control. Its `MUST` / `MUST NOT` / `mandated` statements are obligations the agent is directed to follow; PromptKit OS contains no mechanism that executes or enforces them. The automated CI checks only assert that this file still contains the required invariant text and that directive token budgets hold — they observe no agent behavior. Whether these instructions are followed therefore depends on the host assistant. See §11 for the full boundary and for the current discovery route to this file.

## 1. Purpose & Core Philosophy

**Minimum Sufficient Context**
The goal is not simply to "read as few tokens as possible," but to acquire *sufficient evidence* for the engineering decision, beginning with the lowest-cost useful context and escalating whenever risk, coupling, uncertainty, or verification evidence requires broader context.

## 2. Supreme Invariants

1. **Evidence Primacy**: The AI agent must never guess. If the current context is insufficient to determine the correct behavior, it must acquire more context.
2. **Anti-Starvation**: Context budgets MUST NOT override evidence requirements. If the remaining budget is insufficient to establish correctness-relevant evidence, the agent MUST escalate, request authorization, or halt. It must never proceed with knowingly insufficient context simply because a budget was reached.
3. **Retrieval Confidence is Evidence, Not Authority**: A context provider may supply retrieval evidence, provenance, confidence, and freshness metadata, but PromptKit alone determines whether that evidence satisfies the task's context requirements or requires escalation. High retrieval confidence never bypasses Hard Escalation Triggers.
4. **Provider Freshness & Stale-Index Fallback**: Context from an indexing provider whose freshness cannot be verified must not satisfy freshness-sensitive evidence requirements by itself. For freshness-critical targets (database migrations, authentication, public API contracts, generated code, lockfiles), the agent must fall back to live repository reads.

## 3. The 4D Context Framework

Context in PromptKit OS exists across four dimensions. Agents must consider all four when making engineering decisions:

1. **Spatial**: Where is the code? (Files, line numbers, surrounding symbols, specific execution slices)
2. **Semantic**: What does it mean? (Types, interfaces, DB schemas, API contracts)
3. **Temporal**: Why does it exist? (`docs/STATE.md`, Architectural Decision Records (ADRs), Task Records, git history)
4. **Operational**: What happens when it runs? (Environment variables, async queues, deployment constraints, database states)

## 4. Adaptive Progressive Zoom Ladder (Z0–Z4 Taxonomy)

Agents acquire context in expanding layers termed **Zoom Apertures (Z0–Z4)**. This context aperture is decoupled from PromptKit's **Ceremony / Risk Levels (L0–L3)**:

*   **Task Risk Level (`L0–L3`)**: Defines process governance, planning ceremony, task records, and approval boundaries.
*   **Context Aperture (`Z0–Z4`)**: Defines the physical scope of code and documentation inspected for a given decision.

```text
TASK RISK CEREMONY                    DEFAULT CONTEXT APERTURE

L0: Direct (typos, 1-line tweaks)     Z0: Symbol & Signatures (types, interfaces, AST contracts)
L1: Standard (localized bugs)         Z1: Target & Local Window (symbol body + bounded slice)
L2: Controlled (substantive risk)     Z2+: File & Interface (full target file + imports)
L3: Release-Critical (release safety) Z3+: Module & Dependencies (callers, consumers, shared state)

Context aperture is independent of task risk and may escalate to Z4 (Macro & Architecture) when evidence requires it.
```

**Adaptive Relationship (Risk Informs Aperture, Not Identity)**:
*   An L0/L1 task defaults to Z0/Z1 context, but escalates to Z3 if multiple callers or side-effects are detected.
*   An L2 task requires Z3 (Dependency) validation before writing code touching shared components.
*   An L3 task mandates Z4 (Macro/Architecture) validation and explicit human sign-off.
*   Task risk does not equal context aperture: an L1 bug can occasionally require Z4 context, and an L3 release check can sometimes be validated with Z1 context.
*   **Z1-for-L3 exception (all must hold)**: (1) no §5 Hard Escalation Trigger fires on the change; (2) the check re-verifies scope already Z4-validated with no intervening edits since that validation; (3) explicit human sign-off is still recorded. The exception narrows aperture only — never accountability.

## 5. Hard Escalation Triggers

If an agent encounters any of the following **Hard Triggers**, it is **mandated** to zoom out (escalate context to at least Z3/Z4) and evaluate broader impacts:

*   Modifications to Database Schemas or Migrations.
*   Changes to Authentication, Authorization, or Permissions.
*   Changes to Public Contracts, exported APIs, or core Types.
*   Modifications to Shared Mutable State or Concurrency primitives.
*   Changes crossing package/module boundaries.
*   Modifications to a component with >2 external callers.
*   Unexplained verification failures (tests failing for unclear reasons).

> [!CAUTION]
> **No Bypass by Provider Confidence**: An external retrieval engine reporting high confidence (e.g., `confidence: 0.98`) MUST NOT bypass a Hard Escalation Trigger.

## 6. Soft Escalation Triggers

If an agent encounters any of the following **Soft Triggers**, it should evaluate the need to zoom out:

*   Operating within an unfamiliar subsystem.
*   Encountering unusual or undocumented abstractions.
*   Modifying code lacking adequate test coverage.
*   Low provider retrieval confidence on non-trivial logic.
*   Detecting unexpected side effects during dry-runs.

> [!NOTE]
> **Low Confidence as Signal**: Low retrieval confidence is an escalation signal, not an unthinking automatic command. The agent evaluates provider confidence alongside task risk and hard triggers before deciding whether to zoom out.

## 7. Context Sufficiency Check Gate

Before executing any write operation (file edit, delete, etc.) in an L2 or L3 context, the agent must internally answer the following questions:

1.  *What am I changing?*
2.  *What depends on it?*
3.  *What contract or invariant governs it?*
4.  *What evidence confirms this is sufficiently understood?*

If any question remains unanswered, the agent must not proceed with the write until the context has been appropriately escalated. PromptKit OS does not mechanically block the edit — this is an obligation on the agent, and violating it is a governance failure, not a prevented action.

## 8. Evidence-Driven Diagnostic Zoom

When debugging failures, agents default to a compact root-cause view (e.g., the specific failing assertion and its immediate context). The agent escalates to full stack traces or complete application logs only when the compact evidence is insufficient to explain the failure.

## 9. Context Budgets & Provenance Logging

Agents must log context escalations. If an agent hits a budget threshold but requires more evidence (Anti-Starvation), it must log a `context_escalation` record in the `docs/STATE.md` session log, detailing why the budget was exceeded (e.g., "Hit soft token limit, but required DB schema context to validate safety").

## 10. Context Provider Capability Contract

PromptKit OS defines a vendor-neutral, capability-based interface for context retrieval. PromptKit does not require or bundle any external vector databases, Python runtimes, or indexing daemons. Instead, it defines the contract that any provider (native shell tools, IDE language servers, or MCP tools such as CCE or ACE) can satisfy:

```yaml
context_provider:
  # Mandatory baseline satisfied by standard shell tools (grep, fd, bounded reads)
  required_capabilities:
    - text_search       # Exact keyword or regex match
    - bounded_read      # Line/offset-bounded file slice
    - source_locations  # File paths and line numbers
  # Optional accelerations exposed by rich MCP or AST indexing engines
  optional_capabilities:
    - symbol_search     # Tree-sitter / AST symbol signature extraction
    - semantic_search   # Embedding / vector similarity search
    - lexical_search    # BM25 / full-text ranking
    - graph_expansion   # CALL / IMPORT caller-callee relationship expansion
    - dependency_graph  # Package / module dependency tree
    - confidence        # Statistical retrieval confidence scoring
    - retrieval_method  # Provenance tag (e.g., 'ast', 'vector', 'bm25', 'grep')
    - freshness         # Index timestamp or hash relative to working tree
```

### Provider Adaptation
1. **Minimal Provider (Native CLI)**: Uses `grep`, `find_by_name`, and bounded reads. Satisfies all required capabilities with zero external dependencies. Z0 may be satisfied through native text/search capabilities when semantic symbol extraction is unavailable; `symbol_search` is an optimization, not a prerequisite.
2. **Rich Provider (MCP / Indexing Engine)**: When an active MCP server (such as Code Context Engine or ACE) is detected in the host environment, PromptKit leverages its optional capabilities (e.g., `symbol_search` for Z0/Z1, `graph_expansion` for Z3) while strictly holding PromptKit's Governance, Anti-Starvation, and Hard Escalation Triggers authoritative.

---

## 11. Enforcement Boundary & Discovery Route

Three authorities are easy to conflate here, and they are not interchangeable:

| Layer | What it is | What it actually does |
| :--- | :--- | :--- |
| **Advisory agent instruction** | This document, plus the injected directive | Directs agent behavior. There is no executor: the `MUST` / `MUST NOT` / `mandated` statements above are obligations addressed to the agent, not guarantees about what happens. |
| **Automated CI checks** | `scripts/tests/run-behavioral-contract-tests.sh` and its `.ps1` twin | Assert that this file still contains the required invariant text (`Minimum Sufficient Context`, `Anti-Starvation`, `Hard Escalation Triggers`, `Context Sufficiency Check Gate`, `4D Context Framework`, `Z0–Z4 Taxonomy`, `Context Provider Capability Contract`, `Retrieval Confidence is Evidence, Not Authority`, `Provider Freshness & Stale-Index Fallback`, `required_capabilities`) and that the directive token budgets hold. Text presence is not behavioral compliance, and the suite observes no agent behavior. |
| **Host / runtime enforcement** | The host assistant | Determines whether the directive is actually followed. PromptKit OS ships no daemon, hook, or interceptor that can block an edit, abort a turn, or force a zoom-out; capability varies by host. |

The claim this protocol makes is that the agent is **directed** to escalate and **directed** not to proceed on insufficient evidence. The claim it does not make is that PromptKit OS can prevent an agent from doing otherwise.

**Discovery route (current; not validated as live behavior).** This file is not named in the protocol line of the Balanced or Lite directive — that line lists `setup`, `context-sync`, `code-quality-gate`, and `subagent-delegation`. The route to this file is **transitive**: the directive points at `protocols/setup.md`, whose *Workflows & Protocols Reference* lists `context-economy.md`, and `docs/WORKFLOW-MAP.md` also links it directly. Discovery through that route has **not** been validated with recorded live transcripts, and no automated check exercises it. Balanced/Lite discoverability and sufficiency remain **open acceptance evidence**: documenting the route is not evidence that it works.
