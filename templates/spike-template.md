# Technical Spike Document: [Spike Topic / Decision Name]

- **Author**: [Your Name / Team]
- **Status**: [Proposed | In Progress | Completed | Abandoned]
- **Created**: [YYYY-MM-DD]
- **Timebox**: [e.g., 3 Hours / 1 Day]
- **Stop-Loss Condition**: [e.g., If Candidate B fails to serialize circular state within 2 hours, terminate Candidate B]

---

## 1. Core Spike Question & Sharpest Risk

### Core Question
[State the exact decision question unambiguously, e.g.:
*"Can TanStack Router replace Next.js App Router for our complex multi-tab workspace, while supporting SSR, type-safe search params, and keeping initial JS bundle growth under 15kB?"*]

### The Sharpest Risk (Hardest Constraint)
[Identify the single highest-risk bottleneck or constraint most likely to break this approach in production, e.g.:
*"SSR hydration synchronization with deeply nested dynamic URL search parameters."*]

---

## 2. Candidate Approaches

- **Candidate A (The Boring Baseline)**: [Current tech stack, standard library, or native APIs, e.g., Native Next.js App Router]
- **Candidate B (Leading Modern Standard)**: [Industry leading candidate, e.g., TanStack Router]
- **Candidate C (Specialized Alternative)**: [Lightweight or niche option, e.g., Wouter or React Location]

---

## 3. Multi-Vector Comparative Matrix

> Example values throughout this matrix — replace every cell with measured results; never present these numbers as evidence.

| Evaluation Dimension | Candidate A (Baseline) | Candidate B: [Name] | Candidate C: [Name] |
| :--- | :--- | :--- | :--- |
| **Type Safety & DX** | Partial / Manual casts | Fully inferred from route tree | Strict, lightweight |
| **Runtime Performance (p95)** | ~18ms render | ~8ms render | ~10ms render |
| **Gzip Bundle Size Delta** | 0 kB (already paid) | +12.4 kB | +2.1 kB |
| **TS Typecheck Latency** | Baseline (2.1s) | +0.4s (`tsc` diagnostics) | +0.1s |
| **Ecosystem & Bus Factor** | Internal standard | Massive community (Tanner Linsley) | Solo maintainer |
| **License Compliance** | MIT (Approved) | MIT (Approved) | MIT (Approved) |
| **Operational & Learning Tax** | Zero | 2-3 days ramp up | 1 day ramp up |

---

## 4. Empirical PoC & Benchmark Results

### Sandbox Test Setup
- Repository / branch / scratch path: [e.g., `experiments/tanstack-router-spike`]
- Test scenario: [Stress-testing the sharpest risk]

### Concrete Benchmark Data
```text
[Paste terminal output, benchmark numbers, bundlephobia links, or memory flamegraphs]
- Candidate A Bundle: ...
- Candidate B Bundle: ...
- Latency under 1000 items: ...
```

### Sharpest Risk Verification
- [Did Candidate B overcome the hardest constraint? What edge cases failed?]

---

## 5. Trade-Off Analysis

### What We Gain
- [Advantage 1]
- [Advantage 2]

### What We Sacrifice / Pay
- [Cost 1: e.g., Migration effort, learning curve, innovation token spent]
- [Cost 2: e.g., Dependency maintenance risk]

---

## 6. Final Recommendation & ADR Handoff

- **Verdict**: [Adopt Candidate <X> | Retain Baseline (Candidate A) | No Decision (inconclusive — record open questions) | Disqualified <X> (stop-loss; remaining measures N/A) | Further Spike Required]
- **Key Rationale**: [1-2 sentences justifying the decision based on empirical findings]
- **Next Steps**:
  - [ ] If adopted: Create ADR in `./docs/adrs/YYYY-MM-DD-adr-<slug>.md` using `<kit>/templates/adr-template.md` — only with the decision-policy evidence recorded (exact versions, citations, Planning Record, named-owner approval).
  - [ ] If rejected: Record rationale in progress journal to prevent repeating the spike.
