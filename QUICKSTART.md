# PromptKit OS Quickstart (5 Minutes)

Welcome! This guide gets you productive with PromptKit OS in 5 minutes using the 4 most common workflows.

---

## Step 1: Installation (30 seconds)

### One-Command Setup (Recommended) — 2+1 Profiles

**Balanced is default (23 workflows, Level 0-3 adaptive ceremony):**

```bash
# macOS / Linux (Bash / Zsh) — Balanced default
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --balanced

# Windows (PowerShell)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --balanced
```

**Lite profile — 6 utility workflows (route, debug, commit, checkpoint, sync, profile) <1,500 tok, 80% value — onboarding:**

```bash
# macOS / Linux
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --lite

# Windows
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --lite
```

**Turbo experimental — Balanced + parallel subagent waves, 3-5x token cost, still requires human L3 approval:**

```bash
# macOS / Linux
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --turbo --experimental

# Windows
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --turbo --experimental
```

Profile stored in `PROMPTKIT.md` as `profile: lite|balanced|turbo`. Upgrade anytime: `.promptkit/init.sh --balanced` or `--lite`.
When run in an interactive terminal without flags, `init.sh` / `init.ps1` presents an interactive visual menu to select your profile. In CI or non-interactive environments, pass a profile flag or set `PROMPTKIT_NO_INTERACTIVE=1`.

<details>
<summary>Or install step-by-step</summary>

```bash
# 1. Add as a git submodule
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit

# 2. Run platform setup
./.promptkit/init.sh      # macOS/Linux
.\.promptkit\init.ps1     # Windows
```

</details>

**What this does**: Creates core `docs/` directories (`tasks/`, `specs/`, `adrs/`, `tests/`), scaffolds `PROMPTKIT.md` and `docs/STATE.md`, and injects the lightweight directive router into your AI assistant configuration (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, etc.).

---

## Step 2: Your First Workflow (1 minute)

### Scenario: "I want to understand how to use this system"

**Command**: `pk:route`

```
You: pk:route

AI: [Shows decision matrix]
    - New feature? → pk:plan
    - Bug/crash? → pk:debug
    - Remediation of review finding? → pk:fix
    - Structural code refactoring? → pk:refactor
    - Need guidance? → pk:tutor
    - Code review? → pk:review
```

**What it does**: Acts as your workflow GPS, routing you to the right protocol based on your current task. External skills (such as `skills.sh` skills or host `/skill` commands) act as subordinate helpers; PromptKit OS remains authoritative for task routing, evidence rules, safety boundaries, and human authorization.

---

## Step 3: The Essential Four (3 minutes)

### 🎯 Scenario 1: Planning a New Feature

**Command**: `pk:plan`

```
You: pk:plan - Add user invitation system with email verification

AI: [Guided through 6 phases]
    1. Define problem & non-goals
    2. Design deep modules & seams
    3. Database schema with Expand-Contract migration
    4. FMEA threat modeling
    5. Break into TDD milestones
    6. Generate RFC spec → docs/specs/
```

**Output**: `docs/specs/YYYY-MM-DD-spec-user-invitations.md`

**Key Benefit**: Prevents "code first, regret later" by forcing architectural thinking upfront.

---

### 🐛 Scenario 2: Debugging a Broken Feature

**Command**: `pk:debug`

```
You: pk:debug - Login returns 500 error randomly

AI: [Scientific debugging protocol]
    Phase 1: Build feedback loop (< 3 sec reproduction)
    Phase 2: Minimize to load-bearing core
    Phase 3: Generate 3-5 falsifiable hypotheses
    Phase 4: Tag instrumentation [DEBUG-a4f2]
    Phase 5: 5 Whys root cause analysis
    Phase 6: Write regression test, apply fix
    Phase 7: Clean probes, document RCA
```

**Output**: Fixed code + regression test + optional `docs/rca/YYYY-MM-DD-login-500.md`

**Key Benefit**: Eliminates "shotgun debugging" (random code changes hoping errors disappear).

---

### 🎓 Scenario 3: Learning a New Concept

**Command**: `pk:tutor`

```
You: pk:tutor - How does React Server Components streaming work?

AI: [3-tier progressive hints]
    Tier 1: Conceptual model with ASCII diagrams
    Tier 2: Interface contracts & pseudocode
    Tier 3: Only if blocked - minimal syntax snippets

    [No unsolicited code dumps]
    [Requires teach-back verification]
```

**Modes**:
- `pk:tutor beginner` - Fast confidence building
- `pk:tutor` - Default guided builder
- `pk:tutor architect` - Senior edge-case probing
- `pk:grill` - Staff interview defense drill

**Key Benefit**: You write all code yourself and actually learn instead of copy-pasting.

---

### ✅ Scenario 4: Code Review Before PR

**Command**: `pk:review`

```
You: pk:review - Review my changes against main

AI: [Two-axis audit]
    Axis 1: Spec Fidelity
    - Missing requirements?
    - Scope creep?
    - Implementation bugs?
    
    Axis 2: Technical Standards
    - Fowler's 12 code smells
    - Security (OWASP, data loss prevention)
    - Performance (N+1 queries, indexes)
    - Accessibility (WCAG 2.2 AA)
    - Testing coverage

Severity: 🚨 [BLOCKING] | ⚠️ [IMPORTANT] | 💡 [SUGGEST] | 👏 [PRAISE]
```

**Key Benefit**: Catches issues before CI/CD fails or reviewer feedback.

---

## Step 4: The Magic Commands You'll Use Daily

| When You Need... | Use This | Takes |
|:---|:---|:---|
| **"What workflow do I need?"** | `pk:route` | 10 sec |
| **"Plan a feature properly"** | `pk:plan` | 15-30 min |
| **"Fix this bug scientifically"** | `pk:debug` | Varies |
| **"Learn without code dumps"** | `pk:tutor` | 10-20 min |
| **"Review my code"** | `pk:review` | 5-10 min |
| **"Commit this cleanly"** | `pk:commit` | 2 min |
| **"Pause and hand off session"** | `pk:checkpoint` | 3 min |

---

## Task Ceremony Levels

PromptKit OS automatically adjusts ceremony to match task risk:

| Level | Scope & Examples | Expected Flow | Required Ceremony |
|:---|:---|:---|:---|
| **Level 0 — Direct** | Questions, explanations, README typos, syntax lookups | `understand → change → verify` | Direct execution; no task record |
| **Level 1 — Standard** | Ordinary bug fixes, localized component changes | `understand → plan → implement → test → review` | Natural workflow (`pk:debug`); inline planning |
| **Level 2 — Controlled** | Relational schemas, auth, breaking contracts, risk | `task record → plan → implement → verify` | Task Record (`docs/tasks/`), spec (`pk:plan`) |
| **Level 3 — Release-Critical** | Releases, production deploys, tag generation | `provenance → evaluation → QA → approval` | Candidate evaluation (`pk:ship`), human approval |

---

## Pro Tips

### 1. **You Don't Need to Memorize Commands**
Just describe what you're doing naturally:

```
You: This checkout endpoint is throwing 500 errors

AI: [PromptKit OS: Auto-routed to pk:debug]
    Let's build a feedback loop first...
```

### 2. **Customize for Your Project**
Edit `PROMPTKIT.md` to add:
- Your specific test commands
- Monorepo workspace structure
- Non-negotiable coding standards
- Artifact output paths

### 3. **Session Continuity**
Working on something complex? Use `pk:checkpoint` before ending:
- Syncs progress to `docs/STATE.md`
- Generates handover prompt for fresh chat
- Locks architectural decisions

### 4. **Visual Brand Identity** (Optional)
Create `DESIGN.md` for UI projects (`cp .promptkit/templates/design-profile-template.md DESIGN.md` or ask your AI: `pk:design`):
- Color tokens & anti-slop rules
- Typography standards
- WCAG accessibility requirements
- Component design patterns

AI assistants are instructed to check these in `pk:design` and `pk:review`.

---

## What Makes PromptKit Different?

| Without PromptKit | With PromptKit |
|:---|:---|
| AI dumps 200 lines of code | AI guides you to write it yourself (`pk:tutor`) |
| Guess-and-patch debugging | Scientific hypothesis testing (`pk:debug`) |
| Code first, architecture never | Spec-driven with RFCs (`pk:plan`) |
| Context lost between sessions | Persistent state tracking (`pk:checkpoint`) |
| Inconsistent commit history | Atomic Conventional Commits (`pk:commit`) |
| Destructive schema changes | Zero-downtime migrations (Expand-Contract) |
| Shallow code reviews | Two-axis audits (`pk:review`) |

---

## Next Steps

### 1. **Try Your First Real Task**
Pick one:
- Planning: `pk:plan - [Describe your feature]`
- Debugging: `pk:debug - [Describe the bug]`
- Learning: `pk:tutor - [What do you want to understand?]`

### 2. **Explore More Workflows**
```
pk:route          # See all 23 workflow files and their named aliases
pk:data           # Database design & migrations
pk:auth           # Authentication & RBAC
pk:api            # API contracts & types
pk:test           # Testing strategy
pk:fix            # Surgical remediation of known findings
pk:ship           # Zero-downtime deployment
pk:spike          # Technical research
```

### 3. **Read the Philosophy**
- [README.md](./README.md) - Full system overview
- [protocols/](./protocols/) - Core operating rules
- [workflows/](./workflows/) - Detailed workflow guides

---

## Common Questions

**Q: Do I need to use every workflow?**  
A: No. Most developers use 4-5 regularly (`plan`, `debug`, `tutor`, `review`, `commit`).

**Q: Can I customize workflows?**  
A: Yes. Edit `PROMPTKIT.md` for project-specific rules. Workflows adapt automatically.

**Q: Does this work with my IDE's AI?**  
A: Yes. Compatible with Claude Code, Cursor, Cline / Roo Code, Trae, OpenCode, Windsurf, GitHub Copilot, Gemini CLI, and Aider.

**Q: What if I don't want all the ceremony?**  
A: Simple questions get simple answers (zero overhead). Workflows only activate for substantive tasks.

**Q: Can my team use this?**  
A: Yes. `PROMPTKIT.md` and `docs/STATE.md` are git-tracked, so whole teams stay aligned.

---

## Help & Community

- **Issues**: [GitHub Issues](https://github.com/lowqualityloey/promptkit-os/issues)
- **Philosophy**: See [README.md](./README.md) for the full mental model
- **License**: [MIT](./LICENSE)

---

**You're ready! Start with `pk:route` and let the system guide you.**
