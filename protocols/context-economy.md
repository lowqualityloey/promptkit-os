# Context Economy & Progressive Zoom Protocol

This document establishes the canonical **Context Economy & Progressive Zoom Protocol** for PromptKit OS. It defines how AI coding agents within PromptKit acquire, validate, and constrain the context they consume, ensuring maximum safety and accuracy without wasting token budgets or causing information starvation.

## 1. Purpose & Core Philosophy

**Minimum Sufficient Context**
The goal is not simply to "read as few tokens as possible," but to acquire *sufficient evidence* for the engineering decision, beginning with the lowest-cost useful context and escalating whenever risk, coupling, uncertainty, or verification evidence requires broader context.

## 2. Supreme Invariants

1. **Evidence Primacy**: The AI agent must never guess. If the current context is insufficient to determine the correct behavior, it must acquire more context.
2. **Anti-Starvation**: Context budgets MUST NOT override evidence requirements. If the remaining budget is insufficient to establish correctness-relevant evidence, the agent MUST escalate, request authorization, or halt. It must never proceed with knowingly insufficient context simply because a budget was reached.

## 3. The 4D Context Framework

Context in PromptKit OS exists across four dimensions. Agents must consider all four when making engineering decisions:

1. **Spatial**: Where is the code? (Files, line numbers, surrounding symbols, specific execution slices)
2. **Semantic**: What does it mean? (Types, interfaces, DB schemas, API contracts)
3. **Temporal**: Why does it exist? (`docs/STATE.md`, Architectural Decision Records (ADRs), Task Records, git history)
4. **Operational**: What happens when it runs? (Environment variables, async queues, deployment constraints, database states)

## 4. Adaptive Progressive Zoom Ladder

Agents acquire context in expanding layers. This is not a rigid bureaucratic process, but an **adaptive** one based on the Ceremony Level (L0-L3) and the task's inherent risk.

*   **Level 1 (Orientation)**: Global search, file lists, high-level directory structure.
*   **Level 2 (Target)**: Function signatures, type definitions, interface contracts.
*   **Level 3 (Implementation)**: Specific implementation details, function bodies, internal logic of the target component.
*   **Level 4 (Dependency)**: Upstream callers, downstream dependencies, shared state mutations.
*   **Level 5 (Macro)**: Architecture-wide impacts, documentation updates, database schema changes.

**Adaptability Rules**:
*   **L0 Ceremony** jumps directly to Level 3 (Implementation).
*   **L1 Ceremony** operates primarily at Levels 2-3 (Target & Implementation).
*   **L2 Ceremony** requires Level 4 (Dependency) validation before writing code.
*   **L3 Ceremony** requires Level 5 (Macro) validation and explicit human sign-off.

## 5. Hard Escalation Triggers

If an agent encounters any of the following **Hard Triggers**, it is **mandated** to zoom out (escalate context) and evaluate broader impacts:

*   Modifications to Database Schemas or Migrations.
*   Changes to Authentication, Authorization, or Permissions.
*   Changes to Public Contracts, exported APIs, or core Types.
*   Modifications to Shared Mutable State.
*   Introduction of Concurrency or Threading.
*   Changes crossing package/module boundaries.
*   Modifications to a component with >2 external callers.
*   Unexplained verification failures (tests failing for unclear reasons).

## 6. Soft Escalation Triggers

If an agent encounters any of the following **Soft Triggers**, it should **evaluate** the need to zoom out:

*   Operating within an unfamiliar subsystem.
*   Encountering unusual or undocumented abstractions.
*   Modifying code lacking adequate test coverage.
*   Detecting unexpected side effects during dry-runs.

## 7. Context Sufficiency Check Gate

Before executing any write operation (file edit, delete, etc.) in an L2 or L3 context, the agent must internally answer the following questions:

1.  *What am I changing?*
2.  *What depends on it?*
3.  *What contract or invariant governs it?*
4.  *What evidence confirms this is sufficiently understood?*

If any question remains unanswered, editing is blocked until context is appropriately escalated.

## 8. Evidence-Driven Diagnostic Zoom

When debugging failures, agents default to a compact root-cause view (e.g., the specific failing assertion and its immediate context). The agent escalates to full stack traces or complete application logs only when the compact evidence is insufficient to explain the failure.

## 9. Context Budgets & Provenance Logging

Agents must log context escalations. If an agent hits a budget threshold but requires more evidence (Anti-Starvation), it must log a `context_escalation` record detailing why the budget was exceeded (e.g., "Hit soft token limit, but required DB schema context to validate safety").

## 10. Host / Tool Adapter Boundary

This protocol is agnostic to the host AI environment. It relies on the environment's native tool slicing, MCP servers, or CLI adapters to provide the necessary context views (e.g., reading a specific function instead of a whole file). PromptKit enforces the *rules of engagement*, not the specific tooling implementation.
