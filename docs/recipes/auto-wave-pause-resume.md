---
name: auto-wave-pause-resume
category: recipe
version: 1
token_budget: 1500
description: Worked Turbo wave-boundary pause, checkpoint, and human resume with halt-block schema.
---

# `pk:auto` Wave Pause → Checkpoint → Resume (Turbo Experiment)

Turbo-only. Balanced/Lite behavior is unchanged. This recipe shows the single supported resumable pattern: pause at a wave boundary, persist, human resumes.

---

## 1. The pattern

```text
Wave 1 (workers, max 4)
  ↓
per-task verify
  ↓
checkpoint → docs/STATE.md (+ halt block if parked)
  ↓
HUMAN RESUME (explicit, new authorization for the next wave)
  ↓
Wave 2 ...
```

One park/resume boundary per wave. A resumed wave that parks again halts the run — no recursive parking, no queue.

## 2. Halt-block sample

```yaml
halt:
  reason: strike_exhausted
  wave: 1
  worker: worker-2
  evidence:
    command: npm test
    exit_code: 1
  required_action: human_diagnosis
```

Valid `reason` values: `strike_exhausted` | `review_failed` | `scope_growth`.

## 3. Passive-artifact rule

The halt block is **observable state, never an execution trigger**. Nothing polls it, nothing auto-resumes from it. The human reads it and issues the next authorized run. Any design that watches the record and spawns workers is a scheduler — explicitly out of scope.

## 4. Resume checklist (human)

- [ ] Read the halt block: reason, wave, worker, evidence.
- [ ] Diagnose (fix the worker's task, narrow scope, or accept the park).
- [ ] Start a new authorized run for the remaining waves — authorization never survives the stop.

---

## Related references

- Pause/resume rules: [`workflows/auto.md`](../workflows/auto.md)
- Pre-flight ticks: [`auto-waves-preflight-checklist.md`](./auto-waves-preflight-checklist.md)
- Authority table: [`protocols/code-quality-gate.md`](../protocols/code-quality-gate.md)
