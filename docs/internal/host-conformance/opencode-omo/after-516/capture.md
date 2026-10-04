# OpenCode + OmO post-#516 capture attempt

- Capture date: 2026-10-04 (Pacific/Auckland)
- PromptKit OS revision prepared for post-change run: `1ad473d7d69d00dad059771482f98fb75ef78aff` (`feat(governance): bound external harness authorization`)
- Profile: Balanced
- OpenCode: `1.18.34`
- OmO: plugin configured as `oh-my-openagent@latest`; exact installed version was not resolvable from the plugin directory.
- Configured OpenCode model: `bai/qwen3.8-flash`; no OmO agent-to-model mapping was available for provenance.
- Reset/launch: `opencode auth list`; inspect local OpenCode plugin and model configuration without printing credentials.
- Result: **INVALID / UNTESTED — blocked before session start.** OpenCode reported zero configured provider credentials. No prompt was submitted, no transcript was produced, and no behavioral grade is inferred.
- Probe results (`halt-callout`, `card-provenance`, `breaker-exhaustion`, `greenfield-saas-intake`, `milestone-halt`): Invalid / Untested; no scored transcripts.
- Seed repository SHA, initial/final status, final HEAD, five-minute observation, and repository evidence bundle: Not captured because no model session could start.

This record preserves the post-governance attempt. It is not a live conformance capture and must not be presented as evidence of OpenCode or OmO fidelity. A valid capture still requires a provider-backed run with complete provenance and the bundle format in [`../README.md`](../README.md).
