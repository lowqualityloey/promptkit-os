# Research Workflow (Technical Spikes & Trade-Off Evaluation)

## Fast Shorthand
Trigger anytime with: `pk:spike` or `pk:research` (or `/pk-spike`)

## Mission
Guide the developer through evidence-based **Technical Spikes**, empirical library evaluations, and trade-off analyses.

Eliminate "paper research" (summarizing marketing blogs or hype) and avoid building toy "Hello World" prototypes that fail under production constraints. Enforce rigorous, timeboxed investigations that isolate the sharpest risk, benchmark against the boring baseline, audit licensing and longevity, and transition directly into permanent Architectural Decision Records (ADRs).

---

## Core Spike Principles

### 1. Test the "Sharpest Risk" First
- **Avoid Toy Prototypes**: Most spikes fail because they prove a library works on simple scenarios, while ignoring the complex edge case that kills the project in production.
- **Isolate the Hardest Constraint**: Identify the single highest-risk bottleneck upfront (e.g., SSR hydration streaming, nested dynamic routing, high-concurrency connection pools, complex TypeScript recursive type inference).
- **Fail Fast**: If Candidate A cannot handle the sharpest constraint, disqualify it immediately. Do not waste time benchmarking the easy features.

### 2. The "Choose Boring Technology" Baseline
- Every new external dependency costs an **Innovation Token** (Dan McKinley).
- **Candidate A must always be the existing stack or standard library** (the "Boring Baseline").
- Any new candidate must demonstrate compelling, measurable leverage to justify the adoption tax, maintenance overhead, and mental overhead.

### 3. Strict Timeboxing & Stop-Loss Rule
- Spikes are notorious for expanding into indefinite rabbit holes.
- Every spike must have a strict timebox (typically **2 to 4 hours**, max 1 day) and an explicit **Stop-Loss Condition**:
  > *"If we cannot get Candidate B to serialize nested state within 3 hours, we terminate the spike and declare Candidate B non-viable."*

---

## The Spike Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                   TECHNICAL SPIKE LIFECYCLE                      │
├──────────────────────────────────┬───────────────────────────────┤
│ 1. Sharpest Risk & Timebox       │ 2. Candidate Selection        │
│    Specific hypothesis & stop-loss│   Boring baseline vs. rivals │
├──────────────────────────────────┼───────────────────────────────┤
│ 3. Multi-Vector Matrix           │ 4. Empirical PoC & Benchmark  │
│    DX, Perf, Licenses, Longevity │    Stress-test hardest seam   │
├──────────────────────────────────┼───────────────────────────────┤
│ 5. Synthesis & Trade-Offs        │ 6. Actionable ADR Handoff     │
│    Honest costs and consequences │    Generate docs/adrs/ record │
└──────────────────────────────────┴───────────────────────────────┘
```

---

## Workflow Steps

### Step 1: Formulate the Core Question, Sharpest Risk & Timebox
1. **Core Spike Question**:
   - Frame as an unambiguous, testable decision question:
     > *"Can TanStack Router replace Next.js App Router for our complex multi-tab workspace, while supporting SSR, type-safe search params, and keeping initial JS bundle growth under 15kB?"*
2. **Identify the Sharpest Risk**:
   - What is the single constraint most likely to break this approach?
3. **Establish Timebox & Stop-Loss**:
   - Time budget (e.g., 3 hours).
   - Concrete exit criteria if stuck.

### Step 2: Select Candidate Approaches
Evaluate 2 to 4 realistic options, always including the baseline:
- **Candidate A (The Boring Baseline)**: The existing stack, native APIs, or standard library.
- **Candidate B (Leading Modern Standard)**: The most widely adopted modern solution.
- **Candidate C (Lightweight / Specialized Alternative)**: A high-performance or minimal alternative.

> [!TIP]
> **Subagent Parallel Fan-Out (`protocols/subagent-delegation.md`)**:
> In agentic environments, fan out candidate explorations to concurrent subagents (e.g. Subagent 1 evaluates Candidate A, Subagent 2 benchmarks Candidate B). Require each subagent to return a compact 10-line synthesis adhering to the Multi-Vector Evaluation Dimensions below.

### Step 3: Multi-Vector Comparative Matrix
Audit all candidates across engineering dimensions:

| Evaluation Dimension | Candidate A (Baseline) | Candidate B: [Name] | Candidate C: [Name] |
| :--- | :--- | :--- | :--- |
| **Type Safety & DX** | Partial / Manual | End-to-end inferred | High / Strict |
| **Runtime Performance & Memory** | Baseline | Measure (p95 latency) | Measure (p95 latency) |
| **Bundle Size Impact (Gzip)** | 0 kB (already paid) | Measure via Bundlephobia | Measure via Bundlephobia |
| **TS Compiler Latency** | Baseline | Measure (`tsc --extendedDiagnostics`) | Measure |
| **Ecosystem & Bus Factor** | Internal standard | Active team, 50k+ stars | Solo maintainer |
| **Licensing Safety** | Approved (MIT) | Approved (Apache 2.0) | ⚠️ Risk (AGPL / BSL / Seat) |
| **Migration & Learning Curve** | None | 2-3 days per engineer | High paradigm shift |

---

### Step 4: Build Empirical Proof of Concept (PoC)
Build a minimal sandbox or branch targeting exclusively the **sharpest risk**:

1. **Measure, Don't Guess**:
   - **Bundle Overhead**: Check minified and gzipped bundle size delta.
   - **Throughput / Latency**: Benchmark operations/sec or millisecond response times under load.
   - **Type Ergonomics**: Test whether types infer cleanly without triggering `Type instantiation is excessively deep and possibly infinite`.
2. **Inspect Failure Modes**:
   - What happens when network disconnects?
   - How clear and actionable are error messages during misconfiguration?

---

### Step 5: Document Findings & Verify Claims
1. Cross-reference vendor claims against your empirical PoC results.
2. Flag undocumented gotchas, missing TypeScript generics, or fragile peer dependencies.
3. Check package deprecation history and upcoming vNext breaking roadmaps.

---

### Step 6: Generate Spike Artifact & ADR Handoff
1. Save the full research spike document to `./docs/spikes/YYYY-MM-DD-spike-<topic-slug>.md` using `<kit>/templates/spike-template.md`.
2. **Immediate ADR Generation**:
    - If the spike leads to an architectural decision, transition immediately:
    - Use `<kit>/templates/adr-template.md` to record the decision in `./docs/adrs/YYYY-MM-DD-adr-<decision-slug>.md`.
   - Document: Context, Decision, Considered Alternatives, and Consequences (both positive and negative).

---

## Anti-Patterns to Avoid

| Anti-Pattern | Description | Remedy |
| :--- | :--- | :--- |
| **Paper Research** | Quoting marketing sites without building runnable code. | Mandate an empirical PoC measuring the sharpest risk. |
| **Toy PoC Fallacy** | Testing a trivial "Hello World" and assuming it works at scale. | Test only the hardest edge case or bottleneck. |
| **Ignoring the Baseline** | Forgetting to compare the shiny new tool against the existing stack. | Always evaluate Candidate A (Boring Baseline). |
| **License Blindness** | Adopting libraries with AGPL, SSPL, or commercial restrictions. | Run licensing audit in Step 3 before writing code. |
| **Infinite Spike** | Spending weeks prototyping without a stopping condition. | Enforce strict timebox and stop-loss criteria. |

---

## Completion Criteria
- Sharpest risk empirically tested in a minimal sandbox.
- Multi-vector comparison matrix completed with real benchmark data.
- License and maintenance longevity verified.
- Research spike saved to `./docs/spikes/`.
- Architectural Decision Record (ADR) recorded in `./docs/adrs/` if a decision was made.
