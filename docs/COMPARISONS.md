# Host & Tool Comparisons

How PromptKit OS relates to AI assistant hosts, external skill systems, and alternative approaches. Relocated from the README so the front door stays short; no claim changed.

---

## Host & External Tool Composition

PromptKit OS coexists cleanly with host-specific instruction files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/promptkit.mdc`, `.windsurfrules`, `.clinerules`, `.traerules`, `.opencode/rules.md`, `.github/copilot-instructions.md`), external skill libraries (such as `skills.sh`), host `/skill` commands, and complementary specification systems (Spec Kit, BMad).

### Authority & Governance Boundary

- **Specialized Assistance**: External skills and host tools provide domain-specific knowledge, code generation assistance, or specialized refactoring helpers.
- **PromptKit Authority**: PromptKit OS remains authoritative for **Level 0–3 task classification**, lifecycle routing, required verification evidence, Task Record requirements, release boundaries, and human authorization.
- **Non-Bypass Rule**: External skills must act as subordinate helpers. They must **never** silently commit, push, merge, tag, publish, deploy, or bypass required verification gates.
- **Behavioral Variation**: Host agents enforce instructions with varying degrees of fidelity. PromptKit OS provides protocol standards, but host enforcement depends on the AI agent host.

### Host Compatibility Matrix

| Environment / Tool | Configuration Integration | Repo / CI Validation | Actual Host Behavior Verification |
| :--- | :---: | :---: | :---: |
| **Claude Code** | ✅ `CLAUDE.md` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Claude Code runtime |
| **Antigravity / Gemini CLI** | ✅ `AGENTS.md` / `GEMINI.md` | ✅ CI Behavioral Contract Tests | ⚠️ Dependent on Gemini runtime |
| **Cursor IDE** | ✅ `.cursorrules` / `.cursor/rules/promptkit.mdc` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Cursor Agent runtime |
| **Windsurf IDE** | ✅ `.windsurfrules` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Cascade runtime |
| **Cline / Roo Code** | ✅ `.clinerules` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Cline/Roo runtime |
| **Trae IDE** | ✅ `.traerules` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Trae Agent runtime |
| **OpenCode** | ✅ `.opencode/rules.md` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on OpenCode runtime |
| **GitHub Copilot** | ✅ `.github/copilot-instructions.md` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Copilot runtime |
| **Aider** | ✅ `CONVENTIONS.md` | ✅ CI Syntax & Reference Checks | ⚠️ Dependent on Aider runtime |
| **External Skills (skills.sh / `/skill`)** | ✅ Subordinate helper rules | ✅ Reference Checks | ⚠️ Execution varies by skill implementation |

---

## How PromptKit Differs from Other Tools

| Dimension | Single-File Directives | Static Prompt Packs | Autonomous Multi-Agent Swarms | **PromptKit OS** |
| :--- | :--- | :--- | :--- | :--- |
| **Scope** | Tool-specific instruction endpoint | Workflow templates for one tool | Multi-agent unmonitored loops | Cross-tool engineering OS with 23 lifecycle workflows |
| **Token Overhead** | Minimal initial overhead | High monolithic bloat (~18k tokens inlined) | Higher aggregate token cost from multi-agent pipeline calls | **~1,105 tok Lite / ~2,477 tok Balanced baseline\***  (~94% / ~87% static context reduction vs the ~19.8k derived core-subset baseline (and ~97-99% vs the full 23-workflow set); unused workflows consume 0 tokens) |
| **Persistence** | Per-session only | Per-session only | Hidden cache directories prone to context exhaustion | Git-tracked `docs/STATE.md` survives context resets & fresh chats |
| **Execution Model** | Unstructured chat | Manual template pasting | Background loop until timeout or crash | Disciplined human-in-the-loop pairing (Levels 0–3) |
| **Database Safety** | No schema guardrails | Varies | Risk of destructive drops in unmonitored edits | Expand-Contract only (phased, non-breaking migrations) & strict Project-Scoped DB container isolation |
| **Multi-Agent** | Single agent | Single agent | Unmonitored recursive agent spawns | Subagent delegation with compact synthesis (~98% parent context payload reduction) |
| **Done-Gates** | Trust the model | Trust the model | Fragile timeout heuristics | Artifact gates + Gherkin verification + CI + human review |
| **Lock-in** | Tool-specific format | Tool-specific format | Framework-specific runtime & daemons | Pure markdown, works with any AI coding assistant |

*\* Measured mechanically via `scripts/measure-tokens.sh` / `measure-tokens.ps1` (bytes/4 convention, ~1,105 tokens Lite / ~2,477 tokens Balanced vs the ~19.8k derived core-subset baseline (and ~97-99% vs the full 23-workflow set)). See [`BENCHMARKS.md`](./BENCHMARKS.md) for full context window analysis.*

---

## Related References

- [`../README.md`](../README.md) — Front door: pitch, install, Level model, worked example
- [`BENCHMARKS.md`](./BENCHMARKS.md) — Token economics behind the comparison figures
- [`../FAQ.md`](../FAQ.md) — The 18 questions every developer asks before adopting
