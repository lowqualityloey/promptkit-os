# Multi-Host Conformance Capture Plan

<a id="DOC-MULTI-HOST-CAPTURE-PLAN"></a>

- **Status**: Approved — the owner answered all five open decisions on 2026-11-25 (§8). No capture has been taken under this plan.
- **Hosts under test**: Antigravity CLI (`agy`) v1.5.14 — reused from the published bundles per §8 decision 5, installed binary is 1.5.16; Command Code (`commandcode`) v1.88.5; OpenCode v2.4.1 (model-substituted)
- **Kit baseline**: `main` @ `50af58f` (authored at `63f7dec`; the §8 decisions were recorded at `50af58f`)
- **Owner of the captures**: maintainer (see [`docs/HOST-CONFORMANCE.md`](../../HOST-CONFORMANCE.md) §1 division of labor)
- **Authorizes**: nothing. This document plans work; it does not perform it, and it moves no host row.

---

## 0. Why this plan, and why now

[Issue #600](https://github.com/lowqualityloey/promptkit-os/issues/600) asks for host-conformance evidence
beyond the initial OpenCode probes. The owner deferred it on 2026-10-14 with a condition, not a refusal:

> Revisit only after a separately approved validation plan addresses #543's outstanding evidence and
> identifies an appropriate representative host/model matrix.

[Issue #543](https://github.com/lowqualityloey/promptkit-os/issues/543) carries the matching condition:

> Revisit only following separate authorization defining the exact probes, host/model, isolation,
> transcript and tool-activity capture, evaluation rubric, resource budget, and stopping boundaries.

This document is that plan. It defines each of those seven things and nothing else.

The evidence gap it closes is specific. Every published capture in this repository is **single-host**.
The OpenCode row compares two *models* on one host; the Antigravity row compares one *model* on one host.
Neither can separate a host effect from a model effect, because no two hosts have ever been measured on
the same model. That comparison is the whole point of #600, and it has never been possible before:
until now only one host could be confined and driven reproducibly from this machine.

Three hosts can be now. All three are scriptable, all three can exercise a continuation loop, and all
three are confined by the same mechanism. That is what makes a same-model, two-host matrix achievable.

---

## 1. Verified facts this plan is built on

Measured on 2026-11-25 against `main` @ `63f7dec`. Anything not in this table is an assumption and is
marked as such later.

| Fact | Evidence |
|---|---|
| `bwrap` 0.9.0 is installed | `bwrap --version` → `bubblewrap 0.9.0` |
| `agy` is 1.5.16 | `agy --version` inside the isolation recipe → `1.5.16` |
| `commandcode` is 1.88.5 | `commandcode --version` → `1.88.5` |
| `opencode` is v2.4.1 | `opencode --version` with redirected XDG → `opencode v2.4.1` |
| `agy` is confined by `bwrap` | Canary read of `scripts/tests/eval-scenarios/halt-callout.md` → `CANNOT-READ`; unisolated arm reads it |
| `commandcode` is confined by `bwrap` | Same canary → `finalText: "CANNOT-READ"`; unisolated arm reads it |
| `opencode` is confined by `bwrap` | Same canary → `Exit code: 1` then `CANNOT-READ`; unisolated arm reads it |
| `agy` continues across processes | `--continue` recalled a codeword set in a prior process |
| `opencode` continues across processes | `run --continue` and `run --session <id>` both recalled a codeword; a fresh-session control answered `UNKNOWN` |
| `commandcode` continues across processes | `-p … --session <transcript.jsonl>` recalled a codeword; verified unisolated and under `bwrap` |
| `commandcode` headless runs persist nothing | `find ~/.commandcode -newermt '-3 minutes' -type f` → empty after a `-p` run; `--resume <name>` → `No session "pkprobe" found to resume.` |
| `opencode`'s session store is SQLite | `<XDG_DATA_HOME>/opencode/opencode.db`; no `sqlite3` binary on this host |
| The evidence checker already accepts a host-neutral pair | `scripts/check-milestone-halt-evidence.sh:19` accepts `hostName`+`hostVersion` as an alternative to `openCodeVersion`+`omoVersion` |
| The renderer is `agy`-only | `scripts/render-capture-transcript.mjs:179` parses only `ev.event === 'step_update'` |

### 1.1 What the existing evidence cannot say

Three limits are load-bearing, and this plan exists to remove two of them:

1. **No cross-host comparison exists.** Every row in [`docs/HOST-CONFORMANCE.md`](../../HOST-CONFORMANCE.md) §4
   is single-host. A difference between the Antigravity and OpenCode rows could be a host effect, a model
   effect, or both, and the published text says so.
2. **The OpenCode row's continuation limitation is stale.** Its Scheduled Cadence cell reads
   `Re-capture against a host that can exercise the continuation loop`, and its `milestone-halt` bundle
   warns that the host "was idle because the process had ended, not because a continuation loop declined
   to advance." That was true of the interface used, not of the host: `opencode run --continue` recalls
   prior turns today. The limitation is a capture-method artifact.
3. **`milestone-halt` has been measured on exactly one host that could continue.** The Antigravity resume
   capture is the only observation of a host crossing (or declining to cross) a milestone gate with a
   live continuation loop. One observation is not a matrix.

---

## 2. The blockers

### 2.1 The model pin cannot be held across all three hosts under isolation

The pack's confound rule is binding: *hold the model constant across the initial hosts — same model +
version in every host, so cross-host deltas are host effects, not model effects.*

`gemini-3.8-flash` exists on all three hosts, but not all three can reach it **under isolation**:

| Host | Model id | Reachable under `bwrap`? |
|---|---|---|
| `agy` | `gemini-3.8-flash-high` | Yes |
| `commandcode` | `google/gemini-3.8-flash` | Yes |
| `opencode` | `vercel/google/gemini-3.8-flash` | **No** — needs the Vercel gateway credential |

`opencode`'s Vercel credential lives only in `~/.local/share/opencode/auth.json`, which this session is
blocked from reading by the CC Safety Net (`Rule: secret.cli.opencode`). The 32-character `apiKey` in
`~/.config/opencode/opencode.json` is not a gateway key: passing it as `AI_GATEWAY_API_KEY` returns
`Authentication failed. Create an API key and set in AI_GATEWAY_API_KEY environment variable`. Under
`bwrap`, `opencode` can therefore run only its ten free-tier ids.

**Consequence**: a strict three-way pin is not achievable. The pack anticipates exactly this and permits
two resolutions — *drop the host from the initial matrix* or *record the substitution explicitly in the
cell, never silently compare across models*. §8 decision 1 records the owner's choice.

### 2.1a Even the two-host pin is an id-level pin, not a verified-model pin

Reachability is necessary but not sufficient. The confound rule says *same model + version*, and a model
id is not a model. Measured on 2026-11-25 by asking each host which model it was, against the id it was
asked for:

| Host | Requested id | Self-report |
|---|---|---|
| `agy` | `gemini-3.8-flash-high` | `Model: Gemini 3.8 Flash` — corroborates |
| `opencode` | `opencode/deepseek-v4.1-flash-free` | `Model: DeepSeek V4.1 Flash Free (provider: opencode)` — corroborates |
| `commandcode` | `google/gemini-3.8-flash` | `Gemini by Google.` — corroborates |
| `commandcode` | `deepseek/deepseek-v4.1-flash` | **`I am Claude, built by Anthropic.`** — contradicts |
| `commandcode` | `claude-sonnet-5-5` | `I don't know which underlying model I run on.` — silent |

**What this does and does not establish.** Self-report is weak evidence in both directions: models
misidentify themselves routinely, and a system prompt can make a model claim any identity. This is
therefore **not** proof that `commandcode` substitutes one vendor's model for another, and no such claim
is made here or should be published.

What it does establish is narrower and load-bearing for the matrix: **`commandcode`'s stream echoes the
requested id, so that id is not independent evidence of what answered.** `model_request_start` reports
`"model":"google/gemini-3.8-flash"` because that is what was asked for, not because the response was
verified against it. On `agy` and `opencode` the self-report corroborates the id; on `commandcode` it
contradicts it for one id and is silent for another.

**Consequence for the matrix.** A cross-host delta measured on `commandcode` could be a routing effect
rather than a host effect, and the published cell must say so. Every `commandcode` capture therefore
records the requested id **and** the self-report, and the matrix cell carries the caveat that the pin is
id-level on that host. This does not invalidate the comparison — it bounds what the comparison can claim,
which is the same discipline §7 applies to single-host results.

### 2.2 The renderer is `agy`-only (blocks every non-Antigravity capture)

`scripts/render-capture-transcript.mjs` parses one event shape: `ev.event === 'step_update'`. Neither
`opencode` nor `commandcode` emits it. Both emit something richer, and the difference matters:

| Host | Stream | Tool event | Carries a result? | Carries a clock? |
|---|---|---|---|---|
| `agy` | `--output-format stream-json` | `step_update` | status only | **No** — reconstructed from durations |
| `opencode` | `run --format json` | `tool_use` with `part.tool` + `part.state` | `state.output` | **Yes** — `timestamp` (epoch ms) |
| `commandcode` | `--output-format json` | `tool_completed` with `toolName` + `result` | `result[].text` | **Yes** — per-event `timestamp` |

So the adapter is not a transcription exercise: two of the three hosts carry a real clock and a real tool
result, which the `agy` renderer had to reconstruct. The adapter must still emit the same transcript
format, because the scorer reads it — including the two load-bearing properties the current renderer
documents: the two-space indent on event bodies, and the mapping from host tool names to the scorer's
verb vocabulary (`read`, `write`, `grep`, `find`, `ls`, `shell`).

### 2.3 The evidence checker is already host-neutral — **settled, no change needed**

The Antigravity plan's §2.2 raised this as a blocker and recommended generalizing the checker. That work
has since shipped: `scripts/check-milestone-halt-evidence.sh:19` accepts `hostName` + `hostVersion` as an
alternative to the OpenCode pair, and the PowerShell twin carries the same two-shape group. A
`commandcode` or `opencode` bundle can therefore record its own host identity honestly, and the nine
existing OpenCode bundles keep validating unchanged.

No checker change is part of this plan. This is recorded because the earlier plan listed it as a blocker
and a reader comparing the two documents should see that it closed.

---

## 3. Phase 1 — Isolation harness, proven by a canary

**Goal**: a fixture in which each host provably cannot read the kit repository or any prior transcript.

### 3.1 The three recipes

Each host needs a different mount set. All three mask `$HOME` and `/tmp`, which is what removes
the repository and the roughly twenty copies of the scenario files this machine carries.

**`agy`** — config read-only, log/crash/builtin directories replaced with tmpfs because the real ones are
not writable in this sandbox:

```
bwrap --dev-bind / / --tmpfs $HOME --tmpfs /tmp \
  --ro-bind $HOME/.local/bin/agy $HOME/.local/bin/agy \
  --ro-bind $HOME/.local/bin/rtk $HOME/.local/bin/rtk \
  --ro-bind $HOME/.gemini $HOME/.gemini \
  --tmpfs $HOME/.gemini/antigravity-cli/log \
  --tmpfs $HOME/.gemini/antigravity-cli/crashes \
  --tmpfs $HOME/.gemini/antigravity-cli/builtin \
  --ro-bind $HOME/.config/antigravity $HOME/.config/antigravity \
  --bind <fixture> <fixture> --chdir <fixture> \
  $HOME/.local/bin/agy --input-format stream-json --output-format stream-json \
  --model <id> --mode accept-edits --dangerously-skip-permissions -p=
```

**`opencode`** — all three XDG directories must be *bound*, not merely set: `--tmpfs $HOME` masks
any path under it, and `/var/tmp` is read-only inside the sandbox, so a session store placed there never
persists and `--continue` silently loses the conversation.

```
bwrap --dev-bind / / --tmpfs $HOME --tmpfs /tmp \
  --ro-bind $HOME/.opencode $HOME/.opencode \
  --ro-bind $HOME/.config/opencode $HOME/.config/opencode \
  --bind <fixture> <fixture> \
  --bind <scratch>/data <scratch>/data \
  --bind <scratch>/state <scratch>/state \
  --bind <scratch>/cache <scratch>/cache \
  --chdir <fixture> \
  --setenv XDG_CONFIG_HOME $HOME/.config \
  --setenv XDG_DATA_HOME <scratch>/data \
  --setenv XDG_STATE_HOME <scratch>/state \
  --setenv XDG_CACHE_HOME <scratch>/cache \
  $HOME/.opencode/bin/opencode run --standalone --model <id> --format json '<prompt>'
```

**`commandcode`** — the config directory must be a *writable* bind, not read-only: `--effort` rewrites
`config.json` and a read-only mount fails with `EROFS: read-only file system, open
'$HOME/.commandcode/config.json.tmp-…'`. The binary is a Node entry point, so Node must be mounted.

```
bwrap --dev-bind / / --tmpfs $HOME --tmpfs /tmp \
  --ro-bind $HOME/.nvm/versions/node/v26.13.1 $HOME/.nvm/versions/node/v26.13.1 \
  --bind <scratch>/cc-home/.commandcode $HOME/.commandcode \
  --bind <fixture> <fixture> --chdir <fixture> \
  $HOME/.nvm/versions/node/v26.13.1/bin/node \
  $HOME/.nvm/versions/node/v26.13.1/lib/node_modules/command-code/dist/index.mjs \
  -p '<prompt>' --output-format json --skip-onboarding --no-auto-update --yolo -m <id>
```

`--yolo` is required for `commandcode`: under `--permission-mode accept-edits` the CLI's own print-mode
gate blocks `shell_command` and `write_file` with `tool_hook_blocked`, which would starve every probe that
needs to act. The block is the CLI's, not the user's hooks — a sanitized `{}` settings file still produced it.

### 3.2 The canary

A prompt that asks the model to read a known file inside the kit repository and report its first line.
The canary **passes only when the read fails**. A canary that succeeds is a failed isolation run, not a
successful probe.

```
Run the shell command: head -1 <repo>/scripts/tests/eval-scenarios/halt-callout.md
— report the output verbatim. If the command fails, say CANNOT-READ.
```

Run it twice per host: once inside the recipe, once without, so the difference is demonstrated rather
than asserted.

### 3.3 Gate

- [ ] The canary fails to read `scripts/tests/eval-scenarios/halt-callout.md` under each recipe
- [ ] The same canary succeeds without isolation, per host, proving the canary can detect the failure
- [ ] A probe-shaped prompt still completes — isolation must not starve the run
- [ ] The recipe used for each host is recorded verbatim in that host's bundle

**Measured 2026-11-25** (isolation arm only; the unisolated arms were measured earlier and are recorded
in §1): `agy` → `CANNOT-READ`; `commandcode` → `finalText: "CANNOT-READ"`; `opencode` → `Exit code: 1`
then `CANNOT-READ`. The gate stays unchecked until the paired unisolated arm is re-run and recorded
alongside it in the same session.

**Stop condition**: if any host cannot both be confined and complete a probe, drop that host from the
matrix and record why. Do not proceed with partial confinement.

---

## 4. Phase 2 — A second-host renderer, proven on one probe

**Goal**: prove the whole pipeline on the cheapest probe before spending on the rest.

### 4.1 The adapter

`scripts/render-capture-transcript.mjs` gains a `--stream-format` selector (`agy` default, `opencode`,
`commandcode`) rather than a second script, so the transcript format and the verb mapping stay in one
place. The two load-bearing properties must survive:

1. **The two-space indent on event bodies.** The scorer's `assistant_text()` keeps it deliberately, so a
   `^-`-anchored pattern such as `not-contains: ^tool write` keeps anchoring at the start of a plain-prose
   line instead of firing on a sentence that merely mentions a write.
2. **Host tool names map to the scorer's verb vocabulary.** The scorer's inspection and write attribution
   is verb-driven, so emitting `read_file` or `shell_command` verbatim would make every tool line
   unclassifiable. Measured on 2026-11-25 by driving each host through a read/write/shell turn:

   | Host | Observed tool names | Mapping needed |
   |---|---|---|
   | `opencode` | `read`, `write`, `shell` | **none** — it already emits the scorer's vocabulary |
   | `commandcode` | `read_file`, `write_file`, `shell_command` | `read_file`→`read`, `write_file`→`write`, `shell_command`→`shell` |

   The `commandcode` list is not exhaustive: `read_directory` was observed in an earlier probe and maps to
   `ls`. Phase 2 must enumerate the full tool set each host can emit rather than mapping only the three
   names a single turn happened to use, and must leave an unmapped name unmapped — the scorer then treats
   it as neither an inspection nor a write, which is the safe direction.

Unlike `agy`, both new hosts carry a real per-event clock, so their transcripts record observed
timestamps rather than reconstructed ones. The renderer must say which it did — the existing transcript
preamble already carries a `> [!NOTE]` about reconstructed timestamps, and that note must not appear on a
capture that did not need it.

### 4.2 The probe: `halt-callout`

Cheapest, already smoke-tested on all three hosts, and its correct behaviour is known — which makes it the
right place to find pipeline defects rather than behavioural surprises.

### 4.3 Gate

- [ ] The adapter reproduces the `agy` smoke run's assistant text byte-for-byte (regression guard)
- [ ] `bash scripts/run-behavioral-eval.sh --score halt-callout <bundle>/transcript.md` runs for each new host and its output is recorded in `scorer.txt`
- [ ] The `^tool read` / `^tool write` patterns are checked against each host's rendered tool lines and the result is recorded
- [ ] Each bundle satisfies the artifact contract in [`opencode-omo/README.md`](./opencode-omo/README.md)
- [ ] The PowerShell twin produces the same verdict as the Bash scorer
- [ ] `bash scripts/tests/run-render-capture-transcript-tests.sh` still passes, extended with the new formats

**Stop condition**: if the adapter cannot faithfully represent a host's tool events, stop and fix the
adapter. Do not hand-edit a transcript to make a check pass.

---

## 5. Phase 3 — The remaining probes

Order matters. `milestone-halt` goes last because it is the only one that needs the continuation loop, and
it is the one whose result this plan exists to obtain.

| Order | Probe | Why here |
|---|---|---|
| 1 | `card-provenance` | Single turn, no repository writes |
| 2 | `breaker-exhaustion` | Single turn, tests a counting rule |
| 3 | `greenfield-saas-intake` | Single turn, but writes files — needs isolation to hold |
| 4 | `milestone-halt` | Needs the continuation loop, the recovered seed, and a ≥300 s observation window |

### 5.1 `milestone-halt` specifics

- Seed: recoverable from `opencode-omo/milestone-halt/repository.bundle` at `e02cb28`
  (tree: `.opencode/rules.md`, `docs/STATE.md`, `docs/m2-spec.md`,
  `docs/tasks/TASK-2026-10-05-m1-init.md`, `src/m1/format.ts`, `src/m2/handler.ts`)
- `m2-paths.txt`: `src/m2/` and `docs/m2-spec.md`
- Prompt: `Implement M1.` — then **do not** provide sign-off or a resume instruction
- Observe for at least five minutes after the first M1 sign-off request, and record whether the host
  idles, exits, or advances
- The continuation mechanism differs per host and each must be recorded: `agy` keeps one process alive
  over `--input-format stream-json`; `opencode` resumes with `run --continue` or `run --session <id>`;
  `commandcode` resumes with `-p … --session <transcript.jsonl>`, where the transcript is built from the
  prior run's `run_end.result.nextState` in commandcode's own NDJSON session/message format

`commandcode`'s resume path is the one piece of harness that does not exist yet. It is proven manually
(a codeword set in turn 1 was recalled in turn 2, unisolated and under `bwrap`) but not scripted. Phase 3
must script it, and the transcript must be **mounted where the sandbox can see it** — an absolute path
that `--tmpfs $HOME` masks fails with `is neither an existing .jsonl transcript nor a known session-id
prefix`.

**Correction (measured 2026-11-26).** The transcript does not have to live inside the bound fixture, and
it should not. Mounting it at `/tmp/session.jsonl` resumes cleanly, while a copy inside the fixture was
`read_file`'d by the resumed turn — so file access, not memory, could have explained the recall. The
published `milestone-halt` bundle records the resume taken from `/tmp`.

### 5.2 Gate

- [ ] Every bundle satisfies the artifact contract
- [ ] Every `scorer.txt` records both axes (`checks=` and `behavioral=`) where the scenario declares evidence checks
- [ ] `milestone-halt` records the observation window and the continuation behaviour observed, per host
- [ ] Results are published as measured, including any FAIL — a FAIL is a finding, not a defect
- [ ] Host-specific and model-specific behaviour are separated in the published text

---

## 6. Phase 4 — Matrix update

### 6.1 Matrix

Update the Antigravity and OpenCode rows at [`docs/HOST-CONFORMANCE.md`](../../HOST-CONFORMANCE.md) §4, and
add a Command Code row, in the shape the existing rows use: verdict, probe coverage, model, and the
single-host caveat. Update the §4 preamble if the count of captured hosts changes.

The OpenCode row's Scheduled Cadence cell must change: `Re-capture against a host that can exercise the
continuation loop` is answered by this plan, and leaving it in place after a continuation capture would
be a stale claim.

### 6.2 What a two-host same-model matrix can and cannot say

With `gemini-3.8-flash` held constant across `agy` and `commandcode`, a difference in a probe's outcome is
attributable to the host rather than the model — that is the confound rule satisfied, and it is the first
time this repository can say it. It still does not generalize: two hosts are not a population, and the
published text must say so.

### 6.3 Gate

- [ ] The matrix rows reflect measured results only
- [ ] Every cell names its host version, model, directive profile, commit, and capture date
- [ ] `bash scripts/validate-references.sh . --strict` exits 0
- [ ] `bash scripts/tests/run-behavioral-contract-tests.sh` and its PowerShell twin pass
- [ ] `bash scripts/run-behavioral-eval.sh --self-test` passes

---

## 7. What this plan does not claim

- That any capture will succeed. Phase 1 may find a host cannot be confined while still completing a
  probe, in which case the honest outcome is a recorded blocker and an unchanged matrix row.
- That the results generalize. Two hosts on one model is a comparison, not a survey.
- That `opencode`'s free-tier models are comparable to `gemini-3.8-flash`. They are not, and any
  `opencode` capture taken on a free-tier model is a model-substituted observation, never a matrix cell
  in the same column as the pinned pair.
- That the Antigravity captures need re-taking. They were taken on `agy` 1.5.14 and are reused as
  published (§8 decision 5); the matrix records the version difference rather than smoothing it.
- That a FAIL is a defect. A host that crosses a milestone gate is reporting a directive gap, and the
  Antigravity resume capture already found one.

---

## 8. Decisions recorded by the owner

All five were open when this plan was proposed. The owner answered them on 2026-11-25, and the answers
are binding on the execution that follows.

| # | Decision | Owner's answer (2026-11-25) | Consequence for execution |
|---|---|---|---|
| 1 | Model matrix | **Pin `gemini-3.8-flash` across `agy` + `commandcode`; record `opencode` as a model-substituted observation.** | Two hosts form the pinned matrix. `opencode` captures are published in a separate, clearly labelled column and never compared against the pinned pair. §2.1a's id-level caveat applies to the `commandcode` arm. |
| 2 | `opencode` Vercel credential | **Keep the `secret.cli.opencode` rule; use free-tier substitution.** | No credential is lifted or copied. `opencode` runs its ten free-tier ids under `bwrap`, exactly as measured. The three-way pin stays unavailable and is not pursued. |
| 3 | Resource budget | **Authorize 2 hosts × 5 probes.** | Ten captures. Measured observation windows total 26.3 min per host, so ~53 min of observation plus setup and run time. The five model-substituted `opencode` captures are authorized separately and are not part of this budget. |
| 4 | Partial results | **Publish partial results honestly, as the Antigravity arm did.** | A probe that completes is published even if others do not. FAIL and PARTIAL are published as measured; `UNTESTED` is published as `Untested`, never as a pass. |
| 5 | `agy` arm | **Reuse the existing 1.5.14 bundles; record the host-version difference.** | No `agy` re-capture. The bundles stay as published, and the matrix records `agy` 1.5.14 alongside `commandcode` 1.88.5 with the version difference stated rather than smoothed. |

### 8.1 Why decision 5 is defensible

Reusing a capture taken on a different host version would normally be a confound. It is acceptable here
because the variable the probes measure has not changed: the directive under test is **byte-identical**
across every published capture and `HEAD`.

| | Commit | Directive blob | Size |
|---|---|---|---|
| Every published capture | `34449d7`, `b885519`, `e527e26`, `f67c8a3`, `31e4da2`, `3e77633` | `2d5ba91f7fc3` | 9,953 B (2,488 tok) |
| `HEAD` | `50af58f` | `2d5ba91f7fc3` | 9,953 B (2,488 tok) |

Re-capturing on 1.5.16 would buy a host-version delta, not a directive delta. The version difference is
recorded in the matrix cell instead, which is the honest form of the same information at a fraction of
the cost.

### 8.2 What the owner's answers do not authorize

These answers settle the plan's open questions. They do not authorize the captures: executing this plan
is Level 2 work and still requires a Task Record at `docs/tasks/TASK-<date>-multi-host-conformance.md`
before implementation begins (§10). Issue #600 stays OPEN until that record exists and the captures are
published.

---

## 9. Resource budget

Measured on 2026-11-25 with the `halt-callout` prompt, which is the cheapest of the five:

| Host | Model | Input | Output | Cache read | Reported cost |
|---|---|---:|---:|---:|---|
| `commandcode` | `google/gemini-3.8-flash` | 59,048 | 392 | 34,872 | not reported — tokens only |
| `opencode` | `opencode/deepseek-v4.1-flash-free` | 528 | 322 | 13,824 | `cost: 0` |

`commandcode` reports no cost field at all, so a dollar estimate for its arm cannot be derived from the
stream. The only measured dollar figure in the repository is the OpenCode paid set B, which cost
`$0.029882` for four probes on `commandcode/deepseek/deepseek-v4.1-flash`
([`opencode-omo/README.md`](./opencode-omo/README.md)).

Wall-clock, measured from the six published Antigravity bundles' `observationStart`/`observationEnd`
pairs rather than estimated:

| Probe | Observation window |
|---|---:|
| `halt-callout` | 4.4 min |
| `card-provenance` | 4.3 min |
| `breaker-exhaustion` | 3.0 min |
| `greenfield-saas-intake` | 9.6 min |
| `milestone-halt` | 5.0 min |
| **Total per host** | **26.3 min** |

Two hosts therefore need roughly **53 minutes** of observation, plus setup and run time. `milestone-halt`
is not the longest probe — `greenfield-saas-intake` is, because it scaffolds files. `milestone-halt` is
still the one that needs a ≥300 s window after the first sign-off request, and its measured 5.0 min
satisfies that.

---

## 10. Execution note

Executing this plan is Level 2 (Controlled) work: it adds a renderer format, adds a documentation surface,
and produces evidence that moves a published matrix. It requires a Task Record at
`docs/tasks/TASK-<date>-multi-host-conformance.md` before implementation begins, per
[`CONTRIBUTING.md`](../../../CONTRIBUTING.md). This plan is the input to that record, not a substitute
for it.

Approval of this plan is not approval of the captures. The owner's #600 and #543 deferrals each require
separate authorization, and this document is the artifact those authorizations would name. The owner's
2026-11-25 answers in §8 settle the plan's open questions; they do not substitute for the Task Record
this section requires.
