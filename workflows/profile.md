# Runtime Profile Switcher Workflow (Lite / Balanced / Turbo)

## Fast Shorthand
Trigger anytime with: `pk:profile` (or `/pk-profile`)

## Mission
Switch the workspace's PromptKit OS profile **at runtime, in-session**, without the developer leaving the chat or remembering installer semantics. Detects the active profile, presents the same visual decision as onboarding, then applies the change through the already-tested, idempotent `init.sh` / `init.ps1` re-injection path and verifies the result mechanically.

Profile economics and token budgets are maintained in [`docs/BENCHMARKS.md`](../docs/BENCHMARKS.md) (single source of numeric truth — do not restate measured token values here).

---

## Preconditions & When to Switch
- **Onboarded with Lite, growth needs Balanced** (Level 2/3 work appearing: schema, auth, contracts).
- **Experimenting with Turbo** (parallel subagent waves; requires explicit experimental acknowledgement).
- **Backtracking** after an over-powered install (Balanced → Lite to reduce static overhead).
- **Wrong profile inherited** from a template or team default.

---

## 4-Phase Switch Protocol

```text
┌──────────────┬───────────────┬───────────────┬────────────────┐
│ Phase 1:     │ Phase 2:      │ Phase 3:      │ Phase 4:       │
│ Detect       │ Decide        │ Apply         │ Verify & Close │
└──────────────┴───────────────┴───────────────┴────────────────┘
```

### Phase 1: Detect
1. Read `./PROMPTKIT.md`: parse the machine-readable `profile:` line (authoritative) and the `## 0. PromptKit OS Profile` body.
2. If `PROMPTKIT.md` is missing, do not guess: route to `pk:onboard` (or run `init.sh` with the desired flag), then re-enter.
3. Report current profile to the developer in one line.

### Phase 2: Decide (flags, picker, or non-interactive default)
1. **Flag form**: `pk:profile --lite | --balanced | --turbo --experimental`. A flag is an explicit instruction — skip the picker.
2. **Turbo guard**: `--turbo` without `--experimental` (or without explicit in-chat acknowledgement) is **refused**, mirroring `init.sh`: Turbo is experimental, carries up to ~2x measured token cost, and **never** removes the Level 3 human-approval boundary. No files are touched on refusal.
3. **Interactive, no flag**: invoke the host's native selection tool (`ask_question` / prompt picker) as the final action of this decision step, with the SAME three options as `pk:onboard`:
   - Option 1: current profile — keep unchanged `(Recommended)`
   - Option 2: Lite — 6 workflows, fastest onboarding path
   - Option 3: Balanced — full 23 workflows, Level 0-3 adaptive ceremony
   - Option 4 (only when not already Turbo): Turbo — experimental, requires acknowledgement
   Hosts without native pickers: fall back to `> [!TIP] ### 💡 Choose profile (Type number & Enter):` with the same ordering.
4. **Non-interactive / CI** (`PROMPTKIT_NO_INTERACTIVE=1` or no interactive host): never prompt — apply the flag if given, otherwise default to **Balanced**; state this in the reply.

### Phase 3: Apply (delegate — do not hand-edit directive blocks)
1. Run the platform installer with the chosen flag from the host project root:
   - Linux/macOS: `./.promptkit/init.sh --<profile>` (Turbo: `--turbo --experimental`)
   - Windows: `.\.promptkit\init.ps1 --<profile>` (Turbo adds `--experimental`)
2. The installer idempotently replaces ONLY the `<!-- PROMPTKIT_START -->`-bounded directive block and updates `PROMPTKIT.md` (bottom `profile:` line and `## 0.` body). User-authored content outside the markers is never rewritten.
3. If the installer reports a malformed/orphaned marker error, STOP and surface it (run `pk:sync` after fixing markers manually) — do not append a second block.

### Phase 4: Verify & Close
1. Confirm mechanically:
   - `grep '^profile:' PROMPTKIT.md` shows the new profile;
   - `## 0. PromptKit OS Profile` body matches;
   - directive token size moved in the expected direction: `bash .promptkit/scripts/measure-tokens.sh` (Lite shrinks toward ~850 tok; Balanced grows toward ~2,100 tok; see BENCHMARKS for truth).
2. Display the Dual-Compatible Telemetry Status Card (`📊 / 🎯 / 🟢`) with the new profile, then recommend `pk:sync` so the session hot-reloads the new ruleset from disk.
3. Switching to a lower ceremony profile is a **preference change, not a scope downgrade**: any task already at Level 2/3 keeps its Task Record and evidence gates.

---

## Completion Criteria
- [ ] Profile line AND `## 0.` body agree on the new profile; exactly one directive block present in each configured agent file.
- [ ] Turbo refusal honored when experimental acknowledgement is absent.
- [ ] No prompt rendered in non-interactive contexts (`PROMPTKIT_NO_INTERACTIVE=1`, piped stdin, CI).
- [ ] Token measurement shown post-switch matches expectations for the target profile.
- [ ] `pk:sync` recommended (or executed) so the live session adopts the new directive.

> [!TIP]
> ### 💡 Next Recommended Step:
> - Run **`pk:sync`** to hot-reload the switched ruleset, then continue work — `pk:route` will classify under the new profile.

---

## Related References
- Canonical workflow navigation: [`docs/WORKFLOW-MAP.md`](../docs/WORKFLOW-MAP.md)
- Installer behavior & profile storage: [`protocols/setup.md`](../protocols/setup.md), `init.sh` / `init.ps1`
- Profile economics: [`docs/BENCHMARKS.md`](../docs/BENCHMARKS.md), [`templates/lite-profile.md`](../templates/lite-profile.md)
