# PromptKit OS FAQ

**The 18 questions every developer asks before adopting PromptKit OS.**

---

## 1. How is this different from just writing good prompts?

**Short Answer**: PromptKit OS isn't about better prompts: it's about **structured engineering discipline** that makes AI assistants systematic instead of random.

The Difference:

**Just prompts:**
```
You: "Fix this bug"
AI: [Guesses, dumps code, might work]
You: "That didn't work"
AI: [Guesses again...]
```

**PromptKit (pk:debug):**
```
You: pk:debug - Fix this bug
AI: [Enforced scientific method]
    1. Build feedback loop (< 3 sec)
    2. Generate 3 falsifiable hypotheses
    3. Test systematically
    4. Apply surgical fix
    5. Lock in regression test
```

**Key differences**:
- Workflows are **protocols**, not suggestions
- Forces **structured thinking** (no guess-and-patch)
- **Git-tracked artifacts** (specs, ADRs, STATE.md)
- **Token efficiency** through subagent delegation
- **Persistent memory** across AI context resets

Think of it as: Linux is to commands what PromptKit OS is to AI coding assistants.

**Related**: [QUICKSTART.md](QUICKSTART.md) for workflow examples

---

## 2. Will this actually save me time or add overhead?

**Short Answer**: It speeds you up after the first week. Setup takes 10 minutes, payback period is 36 minutes.

**Time Investment**:
- Setup: 10 minutes (run init script)
- Learning curve: 2-3 hours (first week)

**What feels slower initially**:
- Planning upfront (pk:plan) vs coding immediately
- Writing specs vs jumping to implementation
- Building test loop before debugging

**What's actually faster long-term**:
- Fewer debugging cycles (systematic hypothesis testing vs trial-and-error)
- Higher first-attempt success (spec-first planning reduces rework)
- **Zero context loss** (pk:checkpoint preserves state)
- **No more "what was I doing?"** (STATE.md tracks everything)

**Why the tradeoff pays off**:

| Activity | Without PromptKit | With PromptKit |
|:---------|:------------------|:---------------|
| **Bug fixing** | Guess-and-patch loops | Hypothesis-driven, one pass |
| **Feature planning** | Scattered conversation | Structured spec artifact |
| **Code review cycle** | Multiple back-and-forth rounds | Two-axis audit upfront |

**The "zero overhead" escape hatch**: Simple questions still get direct answers (no workflow ceremony).

---

## 3. Does this work with my AI assistant?

**Short Answer**: Yes, works with all major AI assistants.

| AI Assistant | Compatibility | Configuration File |
|:-------------|:--------------|:-------------------|
| **Claude Code** | ✅ Native | `CLAUDE.md` |
| **Cursor** | ✅ Native | `.cursor/rules/promptkit.mdc` or `.cursorrules` |
| **Cline / Roo Code** | ✅ Native | `.clinerules` |
| **Windsurf** | ✅ Native | `.windsurfrules` |
| **Trae IDE** | ✅ Native | `.traerules` |
| **OpenCode** | ✅ Native | `.opencode/rules.md` |
| **GitHub Copilot** | ✅ Native | `.github/copilot-instructions.md` |
| **Gemini CLI / Antigravity** | ✅ Native | `GEMINI.md` or `AGENTS.md` |
| **Aider** | ✅ Compatible | `CONVENTIONS.md` or manual read |
| **Any AI chat** | ✅ Copy-paste | Manual workflow reference |

**Why it's universal**: PromptKit is pure markdown instructions, not proprietary tool-specific formats.

**Setup**: Init script detects your assistant and configures automatically.

**Example (One-Command Setup — 2+1 Profiles)**:
```bash
# macOS / Linux — Balanced profile (24 workflows, default)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --balanced

# Lite profile (6 utility workflows, 1,146 tokens static overhead)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh --lite

# Windows (PowerShell)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --balanced
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit; .\.promptkit\init.ps1 --lite
```

> **Tip**: If run in an interactive terminal without flags, `init.sh` / `init.ps1` displays a visual menu to choose your profile. For CI/automated setups, pass `--balanced`/`--lite` or set `PROMPTKIT_NO_INTERACTIVE=1`.

**Related**: [QUICKSTART.md](QUICKSTART.md) Section 1 (Installation)

---

## 4. Can I adopt this gradually or is it all-or-nothing?

**Short Answer**: Extremely gradual. Start with one workflow, expand when you're ready.

**5 Adoption Levels** (choose your starting point):

**Level 0: Zero Installation** (5 minutes)
- Try workflows in your AI assistant without installing
- Just paste: "Use pk:debug methodology for this bug"
- No commitment, immediate value

**Level 1: Personal Usage** (10 minutes)
- Install locally (don't commit to team repo yet)
- Use workflows for your own work
- Team doesn't even know you're using it

**Level 2: Team Standards** (30 minutes)
- Commit `.promptkit/` and `PROMPTKIT.md`
- Document existing practices (not changing them)
- Team members opt-in to workflows

**Level 3: Living Documentation** (1 hour)
- Track new decisions in `docs/specs/` and `docs/adrs/`
- Don't backfill old documentation
- Only for new work going forward

**Level 4: Full Integration** (2 hours)
- Active `docs/STATE.md` tracking
- Milestone-based planning
- Team operating system

**Most teams**: Start at Level 1, reach Level 2 in 2 weeks, Level 3 in 2 months.

**What's the minimum?** Just use `pk:debug` and `pk:checkpoint` (Level 1). That alone delivers 80% of the value.

**Related**: [docs/ADOPTION-GUIDE.md](docs/ADOPTION-GUIDE.md) for detailed level breakdowns

---

## 5. What if my team doesn't want to use it?

**Short Answer**: You can use it personally without team buy-in. Even non-users benefit from your better code.

**Personal Usage Strategy**:
```bash
# Install locally (not committed to repo)
git clone https://github.com/lowqualityloey/promptkit-os .promptkit
echo ".promptkit/" >> .git/info/exclude  # Personal gitignore

# Configure your AI assistant only
# Team never sees PromptKit in the repo
```

**What you get**:
- ✅ Faster debugging for you
- ✅ Cleaner commits from you
- ✅ Better code reviews from you
- ✅ Team benefits from higher-quality code you ship

**Convincing skeptical teammates**:

**Don't**: "We should adopt this new process"  
**Do**: Show results

```markdown
# After 2 weeks of personal usage:
"I've been using structured debugging on my last 5 bugs.
Average fix time dropped from 40min to 18min.
Here's the approach if you want to try it..."
```

**Mixed adoption** (common scenario):
```
Team of 8:
- 3 use PromptKit actively
- 5 don't use it but benefit from:
  ✅ Better specs from the 3 users
  ✅ Cleaner PRs from the 3 users
  ✅ Faster onboarding (docs/STATE.md)
```

**Bottom line**: PromptKit works at individual level. Team adoption amplifies benefits but isn't required.

**Related**: [docs/ADOPTION-GUIDE.md](docs/ADOPTION-GUIDE.md) Level 1 (Personal Usage)

---

## 6. Do I really need to write all this documentation?

**Short Answer**: No. Documentation is **optional** and **generated** for you. Minimum usage requires zero documentation.

**Minimum PromptKit** (zero documentation):
```bash
# Just use workflows:
pk:debug - Fix this race condition
pk:checkpoint - Save my progress

# No specs written, no ADRs created
# Just better AI interactions
```

**What gets generated for free**:
- `pk:plan` → Auto-generates `docs/specs/feature-name.md`
- `pk:retro` → Auto-generates `docs/adrs/0001-decision.md`
- `pk:checkpoint` → Auto-updates `docs/STATE.md`

**You write**: Problem description  
**AI writes**: Full documentation artifact

**Example**:
```bash
You: pk:plan - Design user notification system

AI: [Asks clarifying questions]
    [Generates comprehensive 4-page spec]
    [Saves to docs/specs/notification-system.md]

You: [Reviews, edits, commits]
```

**Documentation levels**:

| Level | What You Maintain | Time Investment |
|:------|:------------------|:----------------|
| **None** | Nothing | 0 min/week |
| **Minimal** | `PROMPTKIT.md` only | 5 min one-time |
| **Standard** | Specs for new features | 15 min/feature |
| **Full** | ADRs + STATE.md + specs | 30 min/week |

**Most valuable with minimal effort**: `PROMPTKIT.md` (documents your existing stack/commands once)

**Related**: [docs/DESIGN-MD-FAQ.md](docs/DESIGN-MD-FAQ.md) for DESIGN.md safety guarantees

---

## 7. Is 60-70% token savings realistic or marketing?

**Short Answer**: These are modeled scenario estimates, not telemetry from a production dashboard. The methodology and assumptions are transparent and verifiable.

**How the numbers are derived**: These are modeled scenario estimates that compare typical developer-AI interaction patterns (guess-and-patch debugging loops, scattered planning conversations, repeated context re-explanations) against the structured workflow equivalents. They are not telemetry from a production dashboard.

**Modeled Token Reduction** (scenario estimates, not measured telemetry):

| Scenario | Without PromptKit | With PromptKit | Modeled Savings |
|:---------|:------------------|:---------------|:----------------|
| **Bug fix** | 8,000 tokens | 1,200 tokens | **85%** |
| **Feature planning** | 12,000 tokens | 2,500 tokens | **79%** |
| **Code review** | 4,500 tokens | 1,300 tokens | **71%** |
| **Context handover** | 3,000 tokens | 600 tokens | **80%** |
| **Learning session** | 3,000 tokens | 300 tokens | **90%** |
| **Average** | - | - | **60-70%** |

**Why it works**:

1. **Eliminates guess-and-patch loops** (85% savings)
   - No more "try this... that didn't work... try this..."
   - Systematic debugging finds root cause on first attempt

2. **Subagent delegation** (99% context preservation)
   - Heavy exploration happens in subagents
   - Main context stays lean and focused

3. **Artifacts over conversation** (80% savings)
   - Write spec once → reference forever
   - No re-explaining project context in future sessions

4. **Socratic teaching** (90% savings)
   - 3-tier progressive hints (300 tokens)
   - Not complete solutions (1,500 tokens)

**Cost impact**:

```text
Monthly cost (typical developer):
- Without PromptKit: $12.00/month
- With PromptKit: $3.60/month
- Savings: $8.40/month = $100.80/year per developer

For 10-person team: $1,008/year saved
For 50-person team: $5,040/year saved
```

**How to verify yourself**:
```bash
# Before PromptKit (1 week baseline):
# Track your AI assistant usage/tokens

# After PromptKit (2 weeks later):
# Compare same metrics
# Expected: 50-70% reduction
```

**Not marketing. Modeled estimates based on workflow design principles.**

---

## 8. What's the minimum I need to use (simplest adoption)?

**Short Answer**: Just 2 workflows: `pk:debug` and `pk:checkpoint`. That's it.

**Absolute Minimum** (Level 1 adoption):

```bash
# 1. Install (One-line setup)
git submodule add https://github.com/lowqualityloey/promptkit-os.git .promptkit && ./.promptkit/init.sh

# 2. Use two workflows:

# When debugging (replaces random trial-and-error):
pk:debug - Fix this authentication timeout

# Before ending your session (preserves context):
pk:checkpoint
```

**This alone gets you**:
- ✅ 85% token reduction on debugging
- ✅ Context preservation across sessions
- ✅ No documentation burden
- ✅ Immediate measurable value

**Optional additions** (add gradually):
- Week 2: Add `pk:commit` (clean git history)
- Week 3: Add `pk:review` (self-review before PR)
- Week 4: Add `pk:plan` (plan before building)

**Even simpler?** Level 0 (zero installation):
```
# Just tell your AI assistant:
"Use hypothesis-driven debugging (pk:debug methodology) for this bug"

# No installation, no configuration
# Just better debugging guidance
```

**Recommended path**:
1. Try `pk:debug` on your next bug (today)
2. If helpful, install PromptKit (10 min)
3. Add `pk:checkpoint` to your routine (end of day)
4. Expand to other workflows as needed

**Related**: [docs/ADOPTION-GUIDE.md](docs/ADOPTION-GUIDE.md) Level 1

---

## 9. Can I stop using this without losing my work?

**Short Answer**: Yes, zero lock-in. Remove PromptKit in 2 minutes, keep all your valuable artifacts.

**To remove PromptKit**:
```bash
# Remove the submodule
git submodule deinit .promptkit
git rm .promptkit
rm -rf .git/modules/.promptkit

# Remove configuration (optional)
git rm AGENTS.md  # or CLAUDE.md, .cursorrules, etc.

# Commit removal
git commit -m "chore: remove promptkit-os"
```

**What you keep** (valuable, git-tracked):
- ✅ All specs in `docs/specs/`
- ✅ All ADRs in `docs/adrs/`
- ✅ All artifacts (RCA, perf audits, test plans)
- ✅ `PROMPTKIT.md` (useful reference even without PromptKit)
- ✅ `docs/STATE.md` (project memory)
- ✅ Knowledge and mental models you built

**What you lose**:
- ❌ Workflow structure (pk:debug, pk:plan, etc.)
- ❌ Auto-detected stack context
- ❌ Subagent delegation patterns
- ❌ Token efficiency optimizations

**Can you keep some workflows?**  
Yes! Copy any workflow to your own notes:
```bash
cp .promptkit/workflows/debug.md ~/my-notes/debugging-method.md
# Reference it manually after removing PromptKit
```

**Bottom line**: Your artifacts are yours forever. Removing PromptKit just removes the workflow scaffolding.

**Related**: [docs/ADOPTION-GUIDE.md](docs/ADOPTION-GUIDE.md) Rollback Plan section

---

## 10. What if something breaks or doesn't work?

**Short Answer**: PromptKit is markdown files, not code: very little can break. Here's how to troubleshoot.

**Common scenarios**:

### Workflow doesn't seem to work
```bash
# Verify your AI assistant sees the workflow:
You: "Do you have access to pk:debug workflow?"

AI: "Yes, I can see the debug workflow..."
# ✅ Working

AI: "I don't see that workflow..."
# ❌ Configuration issue
```

**Fix**: Check your config file exists and references `.promptkit/`:
- **Cursor**: `.cursorrules` should have `read .promptkit/workflows/`
- **Claude**: `CLAUDE.md` should reference PromptKit
- **Windsurf**: `.windsurfrules` should include workflows

### AI ignores the workflow structure
```bash
# This means workflow isn't being enforced
You: pk:debug - Fix this bug
AI: [Dumps random code without following methodology]
```

**Fix**: Be more explicit:
```bash
You: Use the pk:debug workflow from .promptkit/workflows/debug.md
     to fix this authentication bug
```

### Init script fails
```bash
# Permission error or git submodule issue
```

**Fix**: Try manual installation:
```bash
git clone https://github.com/lowqualityloey/promptkit-os .promptkit
cp .promptkit/templates/project-profile-template.md ./PROMPTKIT.md
# Edit PROMPTKIT.md manually
```

### Workflow suggests something incorrect
Remember: **AI assistants aren't perfect**. PromptKit structures their reasoning but doesn't guarantee correctness.

**Understanding the enforcement model**: PromptKit is an instruction layer, not a compiler. It cannot mechanically prevent the AI from deviating. What it does provide:
- **Artifact verification**: Did the AI produce `docs/specs/*.md`? Does `docs/STATE.md` reflect the current progress? If not, something went wrong.
- **CI as the mechanical gate**: Your linter, type checker, and test runner still enforce correctness. PromptKit just structures the AI's output so it passes those gates on the first attempt.
- **Human review as the final gate**: `pk:review` produces a structured audit. You review the diff.

**When to override**:
- AI recommendation contradicts your domain knowledge → Trust yourself
- Workflow feels too heavyweight for simple task → Skip it
- Generated spec misses key requirement → Edit the artifact

**PromptKit is a tool, not a boss.** Use your judgment.

**Get help**:
- **GitHub Issues**: https://github.com/lowqualityloey/promptkit-os/issues
- **Discussions**: https://github.com/lowqualityloey/promptkit-os/discussions
- **This FAQ**: Search for related questions

**Emergency escape hatch**: Just stop using workflows and interact with your AI assistant normally. Nothing breaks.

---

## 11. How is this different from .cursorrules, spec-kit, or BMad?

**Short Answer**: Those are tool-specific instruction endpoints or single-purpose templates. PromptKit is a cross-tool engineering operating system with persistent project memory.

**Comparison**:

| Dimension | `.cursorrules` / `CLAUDE.md` | Prompt Packs (spec-kit, BMad) | **PromptKit OS** |
|:----------|:-----------------------------|:------------------------------|:-----------------|
| **Scope** | Single instruction file for one tool | Workflow templates for one tool | 24 workflow files plus named aliases across all tools |
| **Persistence** | Dies with the chat session | Dies with the chat session | `docs/STATE.md` survives context resets |
| **Database safety** | No schema guardrails | Varies | Expand-Contract only (phased migration) |
| **Multi-agent** | Single agent | Single agent | Subagent delegation with compact synthesis |
| **Enforcement** | Trust the model | Trust the model | Artifact gates + CI + human review |
| **Lock-in** | Tool-specific format | Tool-specific format | Pure markdown, works with any AI assistant |

**Key distinction**: `.cursorrules` and `CLAUDE.md` are the **delivery mechanism** (how instructions reach the AI). PromptKit is the **content** (what those instructions actually say). They work together: PromptKit generates your `.cursorrules` or `CLAUDE.md` during initialization.

**Related**: [README.md](README.md) "How PromptKit Differs from Other Tools" section

## 12. Does PromptKit OS waste tokens by loading all workflows into every prompt?

**Short Answer**: No. PromptKit OS uses a **Just-In-Time (JIT) Filesystem Architecture** with zero static token bloat.

**How it works**:
- **Baseline footprint**: Initialization scripts inject only a lightweight 91-line router directive (~1,928 tokens, mechanically measured) into your configuration file (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, etc.).
- **On-demand loading**: The AI only reads specific workflow files (e.g. `workflows/debug.md`) from the local filesystem when that specific workflow is triggered or routed.
- **Comparison to monolithic prompts**: Traditional prompt packs inline all rules, workflows, and templates directly into the prompt on every turn, consuming ~19,794 to ~75,505 tokens statically before work begins. PromptKit preserves ~90% of static context overhead compared to monolithic packs (~19.8k core-subset baseline).
- **Subagent context preservation**: Multi-file exploration is delegated to subagents whose results are synthesized into compact findings, reducing conversational bloat by up to 98%.
- **Mechanical verification**: Measure your exact active directive token footprint anytime using `pwsh -File .promptkit/scripts/measure-tokens.ps1` (or `bash .promptkit/scripts/measure-tokens.sh`).

For complete line-by-line token breakdowns and mathematical analysis, see [docs/BENCHMARKS.md](docs/BENCHMARKS.md).

---

## 13. Does PromptKit OS actually enforce code quality gates, or is it just prompt advice?

**Short Answer**: PromptKit OS defines strict engineering done-gates and cross-session persistence, and its CI, validators, and installer enforce the *artifact and evidence* layer of them. Live agent compliance ultimately depends on the host model — PromptKit is an engineering operating system layered on advice, gates, and durable records, not a runtime that can force a confused model to behave.

**How enforcement works**:
- **Strict Milestone Git Boundaries**: The assistant is strictly prohibited from advancing to a subsequent milestone or major task phase while uncommitted changes exist in the working tree. Tests must pass and atomic staging (`pk:commit`) must occur first.
- **Pre-Commit Quality Gate**: `pk:commit` runs an automated pre-commit scan for secret leaks (`.env`, private keys) and verifies that test runners pass before staging.
- **Verifiable Proof Requirement**: Tasks are not marked complete based on conversational claims alone; the automated verification command (e.g. `npm test`) must produce observable pass evidence.
- **Durable File-Backed State**: State is not lost when chat sessions compact or end. Milestones, tasks in flight, and architectural invariants are committed directly to Git in `docs/STATE.md` and `docs/tasks/`.
- **Pre-Submission PR Gate**: `pk:pr` requires Gherkin Acceptance Criteria checklists and database Expand-Contract safety evaluations before generating pull requests.

---

## 14. How does PromptKit OS maintain readability across both rich markdown IDEs and raw terminal CLIs?

**Short Answer**: PromptKit OS adheres to a strict **Dual-Compatible Visual Callout Standard** without proprietary markup or raw HTML.

**How it works**:
- **Structured Telemetry Status Cards**: Status updates and task completions use a clean 3-line status card (`> 📊 **Milestone**: ... \n> 🎯 **Active**: ... \n> 🟢 **Quality Gate**: ...`) providing instant situational awareness without vertical sprawl or unrendered table syntax.
- **Dual-Compatibility**: In GUI environments (Cursor, Antigravity, GitHub), callouts render as rich GitHub-style visual alerts (`> [!IMPORTANT]`, `> [!NOTE]`). In headless terminal CLIs (Claude Code, Gemini CLI, OpenCode), they render cleanly as bordered accent blocks without unrendered HTML tags or broken table formatting.
- **Interactive Turn Handoffs**: When concluding multi-step tasks, the AI executes native interactive selection tools (OpenCode prompt picker, `ask_question`) as its final action with Option 1 marked `(Recommended)`, letting you confirm your next step with arrow keys, `1`/`Enter`, or custom typing. Bounded to closed-set operational choices: for open intent questions (MVP scope, architecture direction, auth or deployment needs), ask in the context window instead — see the Picker routing rule in `workflows/plan.md`.

---

## 15. How does PromptKit OS prevent tests or migrations from modifying foreign databases on my host?

**Short Answer**: PromptKit OS enforces a strict **Project Database & Harness Isolation** guardrail across all database and testing workflows.

**How isolation is enforced**:
- **Project-Scoped Containers**: Database operations (`pk:data`), schema migrations, seeders, and integration test runners (`pk:test`) are strictly prohibited from attaching to shared or foreign host containers (e.g. `api-db-1` or sibling project instances like `jobtracker`).
- **Explicit Harness Targets**: Test and migration commands must target project-scoped instances (such as `./docker-compose.yml` or dedicated `project-db` containers defined in `PROMPTKIT.md` / `.env.test`).
- **Zero Accidental Contamination**: Prevents test suites or destructive migration scripts from truncating tables, applying schema changes, or dropping databases in neighboring projects.

---

## 16. How does PromptKit OS integrate with Model Context Protocol (MCP) and Docker Desktop MCP Toolkit?

**Short Answer**: PromptKit OS supports MCP as **optional, zero-lock-in accelerators** through a strict **Progressive Enhancement** architecture. If MCP servers (like Sequential Thinking or Fetch) are active via Docker Desktop or stdio, PromptKit OS leverages them; if absent, workflows run seamlessly in pure Markdown / CLI fallback mode without errors.

**Key Principles & Recommended Free Stack**:
- **Progressive Enhancement (No Broken Repos)**: PromptKit OS workflows (`pk:debug`, `pk:plan`, `pk:data`) never mandate MCP tools as hard prerequisites. Team members without Docker or MCP can collaborate on the same repository with identical behavioral outcomes.
- **Recommended Free & Open-Source ($0 Cost) Accelerators**:
  - **Sequential Thinking** (`@modelcontextprotocol/server-sequential-thinking`): Official MIT-licensed local scratchpad tool. Accelerates `pk:debug` Phase 3 (falsifiable hypothesis branching) and Phase 5 (5 Whys RCA) at $0 cost and zero external API dependencies.
  - **Fetch / Jina Reader** (`@modelcontextprotocol/server-fetch` or `r.jina.ai`): Converts live documentation URLs into clean, LLM-optimized Markdown during `pk:plan` with zero HTML noise or paywalls.
  - **Database MCP** (e.g. Postgres / SQLite): Inspects live schema structures directly for zero-downtime `pk:data` checks.
  - **Playwright MCP**: Headless browser automation for `pk:design` UI audits and responsive testing.
- **Token Economics & Zero Static Bloat**: Every active MCP server registers tool JSON schemas that consume context tokens on every single LLM turn. Keep active MCP servers lean (2 to 4 servers max, ~350 static tokens) rather than installing 30+ tool monolithic bundles.
- **Docker Desktop MCP Toolkit vs Direct stdio**:
  - In **Docker Desktop MCP Toolkit**: 1-click containerized profiles without needing Node.js or Python installed on the host OS.
  - In **Standard MCP Clients (Antigravity, Cursor, Claude Code, Cline)**: Configured directly via `npx` / `uvx` stdio in JSON settings with zero container overhead.

---

## 17. How does `pk:refactor` differ from standard TDD or `pk:debug`?

**Short Answer**: `pk:debug` resolves broken behavior; standard TDD adds new behavior test-first. `pk:refactor` modernizes existing architecture **without changing observable behavior**, using Golden Master characterization testing, the Mikado method, and Strangler Fig migrations.

**The Three Distinct Modes**:

| Workflow | Primary Trigger | Invariant Rule | Key Technique |
|:---------|:----------------|:---------------|:--------------|
| **`pk:debug`** | "This is broken / failing / throwing errors" | Behavioral change expected (bug fixed) | Sub-3s reproduction loop, 3 falsifiable hypotheses, 5-Whys root cause |
| **`pk:test`** | "Implement feature X test-first" | Behavioral change expected (feature added) | Red-Green-Refactor, test pyramid seams, fast unit boundaries |
| **`pk:refactor`** | "This code works but is messy / rigid / legacy" | **Zero behavioral change allowed** | Golden Master pinning, Mikado dependency graph, Strangler Fig |

**Why specialized refactoring matters**:
- **Golden Master Pinning**: Captures a snapshot of current outputs (including quirks and legacy edge cases) before a single line of structural code is modified.
- **The Mikado Method**: Graphs prerequisites for large refactorings. If an exploratory refactor breaks tests, changes are immediately reverted (`git reset --hard`) and the missing dependency is recorded as a leaf node.
- **Strangler Fig Migrations**: Replaces legacy submodules incrementally behind facade adapters, preventing high-risk "big-bang" rewrites.

---

## 18. How does PromptKit OS handle a brand-new (greenfield) project with no code yet?

Run `pk:onboard` first. On an empty repo it skips the brownfield scan and runs a **bounded Project Discovery Interview** instead (`protocols/discovery-intake.md`): a size-classed (small / medium / large) set of questions covering MVP intent, target surfaces, deployment target, auth & data needs, constraints, and design references (Figma links, screenshots, `STYLE.md`/`DESIGN.md`, tracker boards). Questions are asked in the context window — not modal pickers — so you can answer with links, screenshots, or documents. The interview closes with a recorded `close_reason`; anything you defer or the AI suggests goes to a **Later ledger**, not the plan. Results land in `PROMPTKIT.md` as machine-readable `size:` / `intake-status:` signals, which `pk:plan` Step 0 consults before proposing architecture. Existing (brownfield) installs resolve to `legacy-partial` and are never re-interviewed.

---

## Still Have Questions?

**More detailed documentation**:
- [QUICKSTART.md](QUICKSTART.md) - 5-minute introduction
- [docs/ADOPTION-GUIDE.md](docs/ADOPTION-GUIDE.md) - Incremental adoption strategy
- [docs/BENCHMARKS.md](docs/BENCHMARKS.md) - Token economics & architecture benchmarks
- [docs/WORKFLOW-MAP.md](docs/WORKFLOW-MAP.md) - Visual workflow decision trees
- [docs/DESIGN-MD-FAQ.md](docs/DESIGN-MD-FAQ.md) - DESIGN.md safety guarantees
- [docs/INTERESTING-FACTS.md](docs/INTERESTING-FACTS.md) - Deep insights

**Community**:
- GitHub Issues: https://github.com/lowqualityloey/promptkit-os/issues
- GitHub Discussions: https://github.com/lowqualityloey/promptkit-os/discussions

---

**Last Updated**: 2026-09-13  
**Version**: 1.5.1  
**Maintainer**: [@lowqualityloey](https://github.com/lowqualityloey)
