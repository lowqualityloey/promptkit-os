# Incremental Adoption Guide for Existing Projects

How to adopt PromptKit OS gradually in legacy codebases, established teams, and production systems **without disrupting active development**.

---

## Philosophy: No Big Bang

PromptKit OS is designed for **gradual adoption**. You don't need to:
- Halt development to "set up PromptKit"
- Refactor existing code to meet new standards
- Force the entire team to switch overnight
- Generate documentation for every past decision

**Start small. Prove value. Expand organically.**

---

## Adoption Levels (Choose Your Starting Point)

### Level 0: Zero Installation (Try Before You Buy)
**Time**: 5 minutes  
**Commitment**: None  
**Goal**: Experience PromptKit workflows without touching your codebase

**Steps**:
1. In your AI assistant, paste this directive:
   ```
   I want to try PromptKit OS workflows. When I ask for help:
   - Debugging → use hypothesis-driven scientific debugging (pk:debug principles)
   - Code review → use two-axis review (spec fidelity + technical standards)
   - Learning → use 3-tier Socratic hints (no code dumps)
   - Planning → require failure analysis before implementation
   ```

2. Try a workflow naturally:
   ```
   You: This login endpoint is randomly failing
   AI: [Applies pk:debug methodology]
       Let's build a tight feedback loop first...
   ```

**Value Delivered**: Structured workflows without configuration  
**Next Step**: If helpful, move to Level 1

---

### Level 1: Personal Usage (One Developer)
**Time**: 10 minutes  
**Commitment**: Optional `.promptkit/` submodule (can be personal, not tracked)  
**Goal**: Use PromptKit for your own work without affecting team

**Steps**:
1. Add PromptKit to your local repo (don't commit yet):
   ```bash
   git clone https://github.com/lowqualityloey/promptkit-os .promptkit
   echo ".promptkit/" >> .git/info/exclude  # Personal gitignore
   ```

2. Configure your AI assistant only:
   - **Claude Code**: Create `CLAUDE.md` (add to `.gitignore`)
   - **Cursor**: Create `.cursorrules` (add to `.gitignore`)
   - **Or**: Keep directives in a personal note file

3. Use workflows in your local branches:
   ```bash
   # Your workflow (hidden from team)
   pk:debug - Fix this race condition
   pk:review - Review my changes before pushing
   pk:commit - Help stage these changes atomically
   ```

**Value Delivered**:
- Better debugging (scientific method)
- Cleaner commits (atomic, conventional)
- Self-code reviews before teammates see code

**When to Advance**: After 1-2 weeks, if you find it valuable, propose Level 2 to your team

---

### Level 2: Team-Shared Standards (Whole Team)
**Time**: 30 minutes  
**Commitment**: Commit `.promptkit/` and `PROMPTKIT.md`  
**Goal**: Align team on standards without disrupting existing workflows

**Steps**:
1. Add PromptKit as a tracked submodule and initialize:
   ```bash
   git submodule add https://github.com/lowqualityloey/promptkit-os .promptkit && ./.promptkit/init.sh
   # On Windows PowerShell:
   # git submodule add https://github.com/lowqualityloey/promptkit-os .promptkit; .\.promptkit\init.ps1

   git add .promptkit/ PROMPTKIT.md
   # Also stage whichever agent config file init created or updated:
   # AGENTS.md (fallback), CLAUDE.md, GEMINI.md, .cursorrules,
   # .cursor/rules/promptkit.mdc, .windsurfrules, .clinerules,
   # .traerules, .opencode/rules.md, or .github/copilot-instructions.md
   git commit -m "chore: add promptkit-os for engineering standards"
   ```

2. Customize `PROMPTKIT.md` for your project:
   - Document **existing** test commands (don't change them)
   - Document **current** tech stack (don't migrate yet)
   - Add non-negotiables you're **already enforcing**

3. **Critically**: Frame as **documentation**, not process change:
   ```markdown
   # In your PR introducing PromptKit:
   
   This PR adds PromptKit OS to document our existing practices:
   - Test commands: `npm test`, `npm run test:e2e`
   - Stack: Next.js 14, PostgreSQL, Drizzle ORM
   - Standards: TypeScript strict mode, HttpOnly cookies, RLS
   
   No workflow changes required. This helps AI assistants understand
   our project conventions automatically.
   ```

**Value Delivered**:
- AI assistants auto-detect your stack
- New team members onboard faster
- Consistent code review standards

**Adoption Strategy**:
- **Opt-in**: Team members can use workflows (pk:debug, pk:review) but aren't required to
- **Passive benefit**: Even non-users benefit from improved AI context

**When to Advance**: After 1 month, if team wants deeper integration, move to Level 3

---

### Level 3: Living Documentation (docs/ artifacts)
**Time**: 1 hour initial + ongoing  
**Commitment**: Track planning artifacts in `docs/`  
**Goal**: Replace scattered Notion/Confluence docs with git-tracked specs

**Steps**:
1. Start tracking **new** decisions only (don't backfill):
   ```bash
   # Next feature planned?
   pk:plan - Design user notification system
   # Output: docs/specs/2024-12-15-notification-system.md
   
   # Made an architecture choice?
   pk:retro - Document why we chose Redis over in-memory cache
   # Output: docs/adrs/0001-redis-cache.md
   ```

2. Use workflows for **new work**:
   - New features: `pk:plan` → spec in `docs/specs/`
   - Bug fixes: `pk:debug` → optional RCA in `docs/rca/`
   - Code reviews: `pk:review` on all new PRs
   - Performance work: `pk:perf` → audit in `docs/perf/`

3. **Do NOT**:
   - ❌ Backfill documentation for old features
   - ❌ Force workflow usage on existing work-in-progress
   - ❌ Require all PR reviews to use pk:review format

**Value Delivered**:
- Searchable decision history (`git log docs/adrs/`)
- Onboarding docs that stay up-to-date
- Audit trail for compliance (SOC2, ISO)

**When to Advance**: After 2-3 months, if team wants full process integration, move to Level 4

---

### Level 4: Full Process Integration (STATE.md + Milestones)
**Time**: 2 hours initial + weekly updates  
**Commitment**: Active `docs/STATE.md` tracking  
**Goal**: PromptKit OS becomes your team's operating system

**Steps**:
1. Initialize `docs/STATE.md`:
   ```bash
   pk:onboard - Scan this codebase and generate STATE.md
   # Reviews git history, tech stack, active branches
   # Generates initial STATE.md with current position
   ```

2. Break upcoming work into milestones:
   ```bash
   pk:tasks - Break "Q1 2024 Roadmap" into milestones and tasks
   # Output: docs/tasks/2024-q1-roadmap.md
   # Optionally sync to GitHub Projects or Jira
   ```

3. Update STATE.md at key checkpoints:
   - **Weekly**: Update task progress, blockers, metrics
   - **End of Sprint**: Run `pk:checkpoint` to compress session
   - **Milestone Complete**: Run `pk:retro` to capture learnings

4. Use handover prompts for collaboration:
   ```bash
   # Developer A ending work:
   pk:checkpoint - Generate handover for team
   
   # Developer B resuming:
   # [Pastes handover prompt into fresh AI chat]
   # AI: "I see you're working on the notification system..."
   ```

**Value Delivered**:
- Zero-loss context across sessions and people
- Persistent project memory (survives AI context resets)
- Metrics-driven retrospectives

---

## Migration Strategies for Common Scenarios

### Scenario 1: You Already Have Linter/Formatter Standards
**Problem**: PromptKit's code quality gate might conflict with ESLint/Prettier

**Solution**: Customize `.promptkit/protocols/code-quality-gate.md`
1. Copy to your project root: `cp .promptkit/protocols/code-quality-gate.md .kiro/steering/code-quality-gate.md`
2. Edit to reference **your** linter commands
3. Keep PromptKit's high-level principles (type safety, security, accessibility)

**Or**: Just document in `PROMPTKIT.md` and ignore the protocol:
```markdown
## Active Commands
- Linter: `npm run lint` (ESLint + Prettier)
- See .eslintrc.json for our existing standards
```

---

### Scenario 2: You Already Use Conventional Commits
**Problem**: Team already follows Conventional Commits, don't need pk:commit

**Solution**: Keep using your existing process
- PromptKit's `pk:commit` is **optional**
- Document in `PROMPTKIT.md` that team already follows Conventional Commits
- Use `pk:commit` only for secret scanning and atomic staging guidance

---

### Scenario 3: You Have Existing ADR/RFC Processes
**Problem**: Team already writes ADRs in a different format or location

**Solution**: Adapt PromptKit templates to your format
1. Keep your existing ADR location (e.g., `docs/architecture/decisions/`)
2. Update `PROMPTKIT.md`:
   ```markdown
   ## Project Artifact Output Paths
   - ADRs: docs/architecture/decisions/ (existing format)
   - Specs: docs/rfcs/ (existing RFC template)
   ```
3. Tell AI assistant:
   ```
   pk:retro - Generate ADR using our existing template in docs/architecture/decisions/
   ```

**Key Insight**: PromptKit is a **workflow system**, not a file format mandate

---

### Scenario 4: Working with Microservices / Multiple Repos
**Problem**: PromptKit is per-repo, but you work across 10+ services

**Solution**: Install in each repo, share common rules
1. Create a shared config repo:
   ```
   company-eng-standards/
   ├── promptkit-shared/
   │   ├── PROMPTKIT-template.md
   │   ├── code-quality-gate.md
   │   └── README.md
   ```

2. In each service repo:
   ```bash
   git submodule add https://github.com/lowqualityloey/promptkit-os .promptkit
   cp ../company-eng-standards/promptkit-shared/PROMPTKIT-template.md ./PROMPTKIT.md
   # Customize per-service
   ```

3. Use `pk:onboard` in each repo:
   ```bash
   pk:onboard - Understand this service's architecture
   # AI learns service-specific context while respecting company standards
   ```

---

### Scenario 5: CI/CD Already Enforces Quality Gates
**Problem**: GitHub Actions already runs tests, linters, security scans

**Solution**: PromptKit complements CI/CD (doesn't replace it)
- **CI/CD**: Automated enforcement (blocks merge on failure)
- **PromptKit**: Pre-commit guidance (catches issues before CI/CD)

**Workflow**:
1. Developer uses `pk:review` locally before pushing
2. Developer fixes issues found by AI assistant
3. Developer pushes to GitHub
4. CI/CD runs as final validation

**Value**: Reduce CI/CD feedback cycles (find issues in seconds, not minutes)

---

### Scenario 6: Supercharging with Model Context Protocol (MCP) Servers
**Problem**: You want your AI assistants (OpenCode, Antigravity, Claude Code, Cursor) to interact directly with GitHub or databases without manual copy-pasting or CLI fragility.

**Solution**: Configure native MCP servers in your assistant environment and document them in `PROMPTKIT.md`. PromptKit OS will automatically prioritize native MCP tool execution:
- **GitHub MCP (`github-mcp-server`)**: PR creation, issue triage, review comments, commit history inspection.
- **Postgres MCP (`@modelcontextprotocol/server-postgres`)**: Live schema introspection, read-only query analysis for `pk:data` and `pk:perf`.

**Precedence Hierarchy**:
$$\text{Native MCP Tools} \rightarrow \text{Native IDE Tools} \rightarrow \text{Terminal CLI Commands} \rightarrow \text{Manual Human Prompt}$$

If an MCP server is missing or disconnected, PromptKit OS gracefully and silently falls back to standard terminal CLI tools (`gh`, `psql`, `git`).

---

## Handling Resistance & Common Objections

### "This Looks Like Bureaucracy"
**Response**: Start at Level 1 (personal usage). Show value through results, not mandates.

**Evidence**:
- "My bug fixes are 40% faster now with pk:debug"
- "Code reviews catch security issues I used to miss"
- "Onboarding new devs takes 2 days instead of 2 weeks"

### "We Don't Have Time to Learn This"
**Response**: You already use AI assistants. PromptKit just makes them better.

**Quick Win**: Run one workflow today
```bash
# Next time you're debugging:
pk:debug - [Describe the bug]
# AI applies scientific method automatically
```

### "Our Process Is Already Working"
**Response**: PromptKit documents your existing process (Level 2) before changing anything.

**Safe First Step**:
1. Create `PROMPTKIT.md` documenting current state
2. Use for 2 weeks
3. Decide if you want Level 3

### "This Won't Scale to Our Team Size"
**Response**: PromptKit is used by solo devs and 50-person teams.

**Scaling Strategy**:
- **Solo/Small (1-5)**: Levels 1-3, informal adoption
- **Medium (5-20)**: Levels 2-4, opt-in workflows
- **Large (20+)**: Level 2 (standards), Level 3 (docs), optional Level 4 per-team

---

## Success Metrics to Track

### Level 1 (Personal)
- Bugs fixed per day (before/after pk:debug)
- Time to isolate root cause (average)
- Commits reverted due to issues (count)

### Level 2 (Team Standards)
- New developer onboarding time (days)
- Code review cycle time (submission → approval)
- Production incidents per month (trending)

### Level 3 (Living Docs)
- Architecture decisions documented (count)
- Time spent searching for "why did we choose X?" (minutes)
- Spec-to-implementation alignment (% of features with specs)

### Level 4 (Full Integration)
- Context handover success rate (smooth vs. restart-from-scratch)
- Sprint predictability (planned vs. completed tasks)
- Technical debt reduction (tracked via STATE.md)

---

## Model Context Protocol (MCP) Acceleration (Optional)

PromptKit OS supports **Model Context Protocol (MCP)** tools as optional accelerators through a strict **Progressive Enhancement** model. If your assistant environment has MCP configured (via Docker Desktop or direct stdio), PromptKit OS leverages it automatically; if not, workflows seamlessly fall back to Markdown and standard CLI tools without disruption.

### Recommended 100% Free / Zero-Cost MCP Stack

| Tool | Protocol Command / Repo | Role in PromptKit OS |
| :--- | :--- | :--- |
| **Sequential Thinking** | `npx -y @modelcontextprotocol/server-sequential-thinking` | **Reasoning Scratchpad**: Powers `pk:debug` hypothesis branching and `pk:plan` architectural tradeoff evaluations. (Free & Open Source / MIT). |
| **Fetch** | `npx -y @modelcontextprotocol/server-fetch` | **Primary Doc Reader**: Fetches clean Markdown of official library documentation during `pk:plan` and `pk:onboard` with zero HTML clutter. |
| **Database MCP** | `@modelcontextprotocol/server-postgres` / `server-sqlite` | **Schema Inspector**: Safe read-only schema discovery for `pk:migrate` (Expand-Contract migrations). |
| **Playwright MCP** | `@executeautomation/playwright-mcp-server` | **UI / E2E Inspector**: Visual verification against `DESIGN.md` tokens and responsive breakpoints during `pk:design`. |

### Client Setup Examples

#### 1. Standard Client Configuration (Antigravity, Cursor, Claude Code, Cline)
Add to your client's MCP configuration settings (`mcpServers` object):

```json
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    }
  }
}
```

#### 2. Docker Desktop MCP Toolkit
1. Open **Docker Desktop** $\rightarrow$ **MCP Toolkit**.
2. Select the **AI coding** template (or add **Sequential Thinking** from the Catalog).
3. Switch to the **Clients** tab and click **Connect** on your preferred editor.

> [!TIP]
> **Token Economics Best Practice**: Keep active MCP servers lean (2 to 4 servers max, ~350 static schema tokens). Loading large monolithic packs (30+ tools) bloats your context window on every prompt and degrades attention on your codebase rules.

---

## Rollback Plan (If It's Not Working)

PromptKit is **zero lock-in**. To remove:

```bash
# Remove submodule
git submodule deinit .promptkit
git rm .promptkit
rm -rf .git/modules/.promptkit

# Remove configuration
git rm PROMPTKIT.md AGENTS.md .cursorrules  # or whichever you added

# Keep docs/ if valuable
# Or delete: git rm -r docs/specs docs/adrs docs/STATE.md

git commit -m "chore: remove promptkit-os"
```

**What you keep**:
- Knowledge gained about your codebase
- Any valuable specs/ADRs written
- Improved AI assistant habits (Socratic learning, scientific debugging)

**What you lose**:
- Workflow structure
- Auto-detected stack context
- Persistent state tracking

---

## Next Steps Based on Your Level

### Currently at Level 0 (Trying it out)?
→ **Action**: Use pk:debug or pk:tutor once this week  
→ **If valuable**: Move to Level 1 (personal usage)

### Currently at Level 1 (Personal)?
→ **Action**: Show 1-2 teammates a workflow in action  
→ **If interested**: Propose Level 2 (team standards)

### Currently at Level 2 (Team standards)?
→ **Action**: Generate 1 ADR or spec using pk:plan or pk:retro  
→ **If useful**: Expand to Level 3 (living docs)

### Currently at Level 3 (Living docs)?
→ **Action**: Initialize docs/STATE.md and track 1 milestone  
→ **If helpful**: Full integration at Level 4

---

## Questions?

- **"Can I adopt partially?"** Yes. Use only the workflows you find valuable.
- **"Do I need all the files?"** No. At minimum, just reference workflows in your AI prompts.
- **"Can I customize workflows?"** Yes. Copy to `.kiro/steering/` and edit.
- **"What if my team uses VS Code Live Share / Cursor?"** Each dev can configure PromptKit in their own assistant.

---

**Remember**: PromptKit OS is a **framework**, not a mandate. Start with what helps you today, expand when you're ready.
