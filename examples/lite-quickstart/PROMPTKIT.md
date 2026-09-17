# Project Architectural Profile (`PROMPTKIT.md`) — Lite Quickstart Example

> **Instructions for AI**: Read this file during every session. This is a minimal Lite-profile project: 6 utility workflows, on-demand directories only.

## 0. PromptKit OS Profile
- **Profile**: `lite` (options: `lite` | `balanced` | `turbo` experimental)
- **Description**:
  - `lite`: 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value — onboarding
- **Upgrade Path**: Run `.promptkit/init.sh --balanced` for the full Balanced profile, or switch in-session with `pk:profile`

profile: lite

size: small
intake-status: complete

---

## 1. Project Overview & Domain
- **Project Name**: Acme Notes (example)
- **Domain / Purpose**: Minimal single-user notes app used to learn PromptKit OS Lite basics
- **Primary Users**: Solo developer learning the Lite workflow subset

---

## 2. Active Technology Stack
- **Language & Runtime**: TypeScript (Strict), Node.js v22
- **Testing**: Vitest (Unit)

---

## 3. Project Commands (Root / Global)
- **Unit Tests**: `pnpm test`
- **Typecheck**: `pnpm tsc --noEmit`
- **Lint & Format**: `pnpm lint`

---

## 4. Monorepo & Workspace Topology (If Applicable)
N/A (Standalone Repository)

---

## 5. Active MCP Capabilities (Optional)
- **Task Tracking System**: Local Markdown (`docs/tasks/` + `docs/STATE.md`)
- **Task Tracking Selector (machine-readable)**: `tracking: local`

---

## 6. Documentation & Artifact Storage Paths
Lite keeps specialized dirs on-demand only:
- **Living project state**: `docs/STATE.md`
- **Architectural Decision Records (ADRs)**: `docs/adrs/` (created when the first ADR is written)

---

## 7. Non-Negotiable Architecture Rules & Guardrails
- [ ] **Absolute Secret Hygiene**: Never paste, expose, or request secrets, API keys, or credentials in chat.
- [ ] **Atomic Conventional Commits**: One concern per commit (`pk:commit`).
- [ ] **Context Window Reset Threshold (~30 Turns)**: When conversation approaches ~30 turns, run `pk:checkpoint` and continue in a fresh session via `pk:route`.

tracking: local
