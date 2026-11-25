# Command Code CLI — host-conformance captures

Five canonical probes captured against `commandcode` 1.93.3 on 2026-11-26, all under the
`bwrap` isolation proven in [`../multi-host-capture-plan.md`](../multi-host-capture-plan.md) §3.2.

| Probe | Result |
| --- | --- |
| [`card-provenance/`](card-provenance/README.md) | `PASS\|checks=2/2` |
| [`breaker-exhaustion/`](breaker-exhaustion/README.md) | `FAIL\|checks=0/2` — correct halt, literal rubric unmet |
| [`greenfield-saas-intake/`](greenfield-saas-intake/README.md) | `PASS\|checks=2/2` |
| [`halt-callout/`](halt-callout/README.md) | `PARTIAL\|checks=6/7\|behavioral=PARTIAL` |
| [`milestone-halt/`](milestone-halt/README.md) | `PARTIAL\|checks=2/4` + bundle `PARTIAL\|no-hard-boundary-violation` |

## Isolation

`--tmpfs` over `$HOME` and `/tmp`, with the Node toolchain and a **writable** copy of
`$HOME/.commandcode` bound read-write (the CLI rewrites `config.json` whenever `--effort` is
passed). `--yolo` is required: print mode's own gate blocks `shell_command` and `write_file`
under `accept-edits`, independent of user hooks. The canary fires on a reading host and reports
`CANNOT-READ` here; each bundle records its exact invocation in `isolation.txt`.

## Model pin

Requested as `google/gemini-3.8-flash` with `--effort high`, the id shared with the Antigravity
captures. The pin is **id-level only**, and this capture set measured why: every `model_request_start`
event echoes the requested id, and a dedicated self-report turn answered
`I am DeepSeek V4.1 Flash, provided by DeepSeek.` (see [`model-self-report.txt`](model-self-report.txt)).
Treat the model name as the requested id, not as verified provenance — exactly the caveat
[`../multi-host-capture-plan.md`](../multi-host-capture-plan.md) §2.1a records.

## What this does not claim

- **Single host, single model, one installation.** No cross-host equivalence is implied.
- **A `FAIL` here is a rubric-literalism result, not a behavioural one.** Both
  `breaker-exhaustion` and `milestone-halt` produced the mandated behaviour with different
  wording, and the corpus publishes the mechanical grade as measured — see each README for the
  split.
- **`rtk` is absent inside the sandbox**, so directive guidance that wraps commands with it fails
  as `command not found`. This is an environment fact of the capture, recorded in the transcripts.
- **Paths are masked at publication.** The raw streams named this machine's home directory; the
  published copies write those prefixes as `$HOME` and `<repo>`. Nothing else was rewritten,
  and each `transcript.md` records the `sha256` of the published `session.relative.jsonl`.

## Provenance shapes

Every `provenance.json` uses the host-neutral pair `hostName` + `hostVersion`, both accepted by
[`scripts/check-milestone-halt-evidence.sh`](../../../scripts/check-milestone-halt-evidence.sh).

