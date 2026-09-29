# Senior Developer Knowledge Base

Welcome to your personal engineering knowledge base. This workspace operates as your **Second Brain**, structured to retain high-leverage mental models, architectural decisions, technical research, and deliberate practice goals.

---

## Workspace Structure

```
notes/
├── learning-plan.md         # Active engineering OKRs, skill targets, and open deep-dive questions
├── progress-journal.md      # Multi-dimensional retro log (learnings, trade-offs, and tags)
├── skill-matrix.md          # Multi-tiered Competency Matrix (Junior -> Mid -> Senior -> Staff)
├── adrs/                    # Local ADR directory (for standalone vault mode)
│   └── README.md            # Index and guidelines for recording architectural choices
└── spikes/                  # Local Spikes directory (for standalone vault mode)
    └── README.md            # Index and guidelines for research notes
```

> **Host Project Note**: When working inside an active project codebase, ADRs and RFC specs are stored directly in your project's `./docs/adrs/` and `./docs/specs/` directories so that project documentation is committed to the project's Git repository.

---

## Recommended Engineering Habits

### 1. Weekly Planning (`pk:tutor` / `pk:plan`)
- At the start of each sprint or week, review `skill-matrix.md` and set 2-3 high-impact goals in `learning-plan.md`.
- Document key technical questions you want to explore with your AI mentor before writing code.

### 2. Daily / Block Retrospectives (`pk:retro`)
- At the end of each development session, trigger `pk:retro`.
- Ingest git diffs to extract key insights, design trade-offs, and mental model shifts.
- Keep `progress-journal.md` updated as a living engineering logbook.

### 3. Architecture Decisions & Spikes (`pk:spike` / `pk:plan`)
- When evaluating major architectural patterns or libraries, run a spike via `pk:spike`.
- When a decision is solidified, record an ADR in the host-owned `./docs/adrs/` using the read-only kit source `<kit>/templates/adr-template.md`.

---

## Archiving & Long-Term Value
Your notes are portable and project-agnostic. Keep this repository linked across your personal and professional projects to preserve your engineering knowledge compounding over time.
