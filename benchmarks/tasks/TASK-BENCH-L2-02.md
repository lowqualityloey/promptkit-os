# Task Spec: Guard the context-economy discovery route

<!-- Real backlog slice from issue #596: the protocol documents a transitive
     discovery route (directive -> setup.md -> context-economy.md) and says no
     automated check exercises it. This L2 task adds that regression guard in
     both behavioral-contract twins and corrects the disclosure. Live transcript
     validation of actual agent discovery remains open. -->

- **Task ID**: `BENCH-L2-02`
- **Level**: `L2`
- **Seed Repository**: `promptkit-os (this repository; operator supplies --seed)`
- **Prompt**: `"Add a regression guard for the documented transitive discovery route to protocols/context-economy.md. In both scripts/tests/run-behavioral-contract-tests.sh and scripts/tests/run-behavioral-contract-tests.ps1, add a new scenario with assertions that templates/agent-directive-template.md and templates/agent-directive-lite-template.md reference setup in their protocols line, that protocols/setup.md lists context-economy.md in its workflows and protocols reference, and that docs/WORKFLOW-MAP.md links context-economy.md. Update the Discovery route paragraph in protocols/context-economy.md so it no longer claims no automated check exercises the route, while keeping the statement that live transcript validation remains open. Add an Unreleased Changed entry to CHANGELOG.md for this documentation correction (issue 596). Do not change the directive templates, protocols/setup.md, or docs/WORKFLOW-MAP.md. Do not edit any other file. Run both behavioral-contract suites and make them pass."`
- **Setup**: `None`
- **Verify**: `bash scripts/tests/run-behavioral-contract-tests.sh && /usr/bin/pwsh -NoProfile -File ./scripts/tests/run-behavioral-contract-tests.ps1`

## Rubric

- [ ] `R1`: The Bash behavioral-contract suite contains a new scenario or assertion block covering the full documented route: the Balanced and Lite directives reference setup in their protocols line, `protocols/setup.md` lists `context-economy.md`, and `docs/WORKFLOW-MAP.md` links `context-economy.md`.
- [ ] `R2`: The PowerShell twin contains equivalent assertions for the same route.
- [ ] `R3`: The Discovery route paragraph in `protocols/context-economy.md` no longer claims that no automated check exercises the route, and it still states that live transcript validation remains open.
- [ ] `R4`: `CHANGELOG.md` `[Unreleased]` has a Changed entry for this documentation correction (referencing issue #596).
- [ ] `R5`: Both behavioral-contract suites pass; the verify packet shows `verify_exit=0` and no failures in either summary.
- [ ] `R6`: The directive templates, `protocols/setup.md`, and `docs/WORKFLOW-MAP.md` are unchanged; only the two test twins, `protocols/context-economy.md`, and `CHANGELOG.md` are modified.

## Notes

- Source issue: #596 (`docs(context): clarify advisory Context Economy and improve protocol discoverability`).
- The guard asserts the documented link chain, not live agent behavior; the
  issue's requirement for recorded live transcripts remains open and must not
  be claimed as satisfied.
- The directives list protocols in a brace form, so the assertion must match
  the actual `protocols/{setup,...}.md` shape rather than a literal
  `protocols/setup.md` string.
