# Architecture Decision Records (ADRs)

This directory stores permanent **Architectural Decision Records** when running PromptKit OS in standalone study/vault mode. In an active project, ADRs are saved directly to the host project's `./docs/adrs/` folder so they are committed to the project's Git repository.

---

## What is an ADR?
An ADR is a lightweight document that captures a significant architectural decision made in software development, along with its context, considered alternatives, and consequences.

---

## How to Create an ADR
1. When a key architectural decision is reached during `pk:plan` or `pk:retro`, copy the read-only kit source `<kit>/templates/adr-template.md` into the host-owned `./docs/adrs/` (or this directory if in standalone vault mode).
2. Name the file using the format:
   `YYYY-MM-DD-<decision-title>.md` (e.g., `2026-08-23-adopt-trpc-for-type-safe-apis.md`).
3. Fill in Context, Decision Drivers, Considered Options, Outcome, and Trade-Offs.
4. Keep the status updated (`Draft` -> `Accepted` -> `Superseded`).

---

## ADR Index Table
| Number | Date | Title | Status |
| :--- | :--- | :--- | :--- |
| ADR-001 | 2026-08-23 | Example: Adopt Clean Architecture Boundaries | Example only — no decision recorded |
