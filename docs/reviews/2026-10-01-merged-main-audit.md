# PromptKit OS merged-main audit

- **Date:** 2026-10-01 (Pacific/Auckland).
- **Repository:** lowqualityloey/promptkit-os.
- **Reviewed commit:** `61e7e36584468cd8e95de8c29e358eea49a72d52`. GitHub main was unchanged at the final revision check.
- **Result:** 22 retained source findings: **2 P1**, **20 P2**. P1 means fix with priority; P2 means a concrete correction for the affected scenario.
- **Execution coverage:** existing Linux and Windows CI passed at this exact commit. Local runtime verification remains **INCOMPLETE** because the command runner fails before launching a process.
- **Changes:** this audit adds a report and evidence ledger only. No implementation changes, commits, GitHub reviews, comments, or issues were published.

## Highest priorities

1. Fix the PowerShell marker replacement that can delete user-authored instructions.
2. Remove raw credential-bearing output from the commit probe check.
3. Make installer updates transactional and preserve permissions and destination boundaries.
4. Correct release validation failure handling and missing release-chain checks.
5. Repair the published environment/webhook examples and distinguish host fixtures from live results.

## Findings

### F01 — [P1] PowerShell marker replacement can delete user prose

**Source:** [init.ps1:706–734][f01].

Marker validation counts lines containing exactly START/END, but replacement uses an unanchored, whole-content regular expression. A user preamble containing an inline START-marker example followed by one valid managed block passes validation. Replacement starts at the inline example and consumes user prose through the managed block's END.

**Impact:** installation/update deletes instructions outside the managed block despite the preservation contract.

**Correction:** replace using the validated line boundaries, or an equivalently anchored pattern that cannot match marker examples outside the managed block. Preserve the original bytes outside that block.

### F02 — [P1] Commit probe cleanup can print a removed credential

**Source:** [workflows/commit.md:89–103][f02].

The probe command prints raw staged-diff lines matching debug patterns. Removing an old debug statement containing a live credential passes the additions-only staged scanner; the subsequent probe check prints the deleted credential line. It also treats deleted probes as though they remain in staged content.

**Impact:** a cleanup operation can expose a credential in terminal output, logs, and agent context.

**Correction:** inspect staged additions without emitting raw content. Return only a redacted location/category or a quiet detection result; disable external diff/text conversion here as in the secret scanner.

### F03 — [P2] The filename gate exempts a real credential file

**Source:** [workflows/commit.md:94][f03]; [sensitive-path registry:5][sensitivepaths].

The safe-template exclusion includes `.env.test`, although preflight classifies that filename as sensitive. A staged test environment containing a credential-bearing database URL can evade both the filename gate and the limited credential-pattern scanner. The separate preflight warning is advisory.

**Correction:** remove `test` from the exemption and match only exact approved template filenames. A test database configuration is not automatically a safe public template.

### F04 — [P2] Installer destinations can escape the selected project through links

**Source:** [init.sh:578–589][f04discovery], [init.sh:756][f04bash], [init.ps1:754][f04ps].

Existing linked host files pass discovery. Bash initial injection appends through the link; PowerShell writes through it. A project `AGENTS.md` linked to another repository therefore modifies that other repository. A linked parent directory similarly defeats the lexical project-relative custom-target check.

**Correction:** validate resolved destination containment, including parent links. Require explicit authorization for an external destination before writing it. This finding concerns destination scope; no malicious repository or exploitation was observed.

### F05 — [P2] Bash cannot update an existing Cline file installation

**Source:** [init.sh:613–635][f05].

Cline detection recognizes a legacy `.clinerules` file. Registration subsequently insists on `.clinerules/promptkit.md` and attempts to create the existing file as a directory. A normal rerun or `--add-host=cline` exits instead of updating it. PowerShell already distinguishes the file and directory layouts.

**Correction:** reuse a detected file target; create the nested target only for the directory layout.

### F06 — [P2] Bash splits a quoted custom path into separate targets

**Source:** [init.sh:78–85][f06args], [init.sh:593–606][f06loop].

`--target="docs/AI Instructions.md"` is stored in a space-separated string and later iterated without quoting. It creates/injects `docs/AI` and `Instructions.md` rather than the requested file. Globbing can also alter the target set.

**Correction:** store targets in an array and iterate quoted elements.

### F07 — [P2] Failed profile switches leave a partially updated installation

**Source:** [init.sh:364–403][f07bash], [init.ps1:369–410][f07ps]; later marker rejection at [init.sh:698–706][f07validation].

Both installers rewrite the authoritative profile before validating all host targets and marker blocks. Switching Lite to Balanced with an orphaned marker fails after `profile: balanced` has already been written, leaving the existing Lite directive in place. With multiple targets, earlier directive updates can also survive a later failure.

**Correction:** prevalidate every target, prepare updates, and commit the profile and directives together, with rollback for write failures.

### F08 — [P2] PowerShell overwrites an explicitly supplied Profile parameter

**Source:** [init.ps1:80–97][f08flag], [init.ps1:150–157][f08override].

The declared `-Profile` parameter does not initialize `$ProfileSet`. Running an update with `-Profile balanced` against an installed Lite profile consequently reloads Lite and ignores the explicit selection. Switch aliases take a different path and do set the flag.

**Correction:** initialize explicit-option flags from `$PSBoundParameters`, then apply installed defaults only to unbound options.

### F09 — [P2] PowerShell worktree helpers announce success after Git failure

**Source:** [scripts/isolate-worktree.ps1:71–90][f09].

Creation and merge never check the native command exit code. An existing branch can make worktree creation fail; a conflict can make a human-executed merge fail. Both branches nevertheless print success. `$ErrorActionPreference = "Stop"` alone does not turn native nonzero exits into terminating errors under default PowerShell settings. [Microsoft preference documentation][psnative].

**Correction:** inspect the exit code immediately and exit nonzero before success messages or dependent actions.

### F10 — [P2] Bash updates lose restrictive permissions on macOS/BSD tools

**Source:** [init.sh:717–751][f10].

The installer preserves mode on one temporary file with `cp -p`, then replaces that inode with a newly created `.content` file. Its only mode transfer is GNU `chmod --reference`, whose failure is suppressed. With BSD chmod and umask 022, an existing 0600 directive file becomes 0644.

**Correction:** preserve mode using a portable operation before replacement. Current Ubuntu/Windows CI does not establish macOS behavior.

### F11 — [P2] PR checks hardcode main despite a different selected base

**Source:** [workflows/pr.md:13][f11pre], [workflows/pr.md:36–46][f11].

The workflow permits a target base branch and remote, but comparison and conflict instructions hardcode `main`. A PR targeting `release/1.x` gets the wrong history/diff and never checks divergence against its actual target.

**Correction:** resolve the complete remote/branch once and use it consistently for history, diff, fetch, and conflict preparation.

### F12 — [P2] Worktree reconciliation instructs agents to perform a human-only merge

**Source:** [protocols/subagent-delegation.md:125–127][f12]; executable [Bash merge:77][f12bash] and [PowerShell merge:89][f09].

Pattern D tells the parent to run the merge helper after verification. That helper executes `git merge`. The [action authority model:130–137][authority] explicitly reserves every merge for a human, including authorized automated runs.

**Correction:** have the agent prepare verification and reconciliation instructions; explicitly assign execution of the merge to the human. Keep the helper available for human use.

### F13 — [P2] Uncommitted reviews silently drop their diagnostics and verifier diff

**Source:** [workflows/review.md:53–84][f13]; [verifier input:301][f13verifier].

The workflow correctly selects staged or working-tree review, then diagnostics and fresh-context verification recompute a committed-only three-dot diff. For uncommitted changes directly on main, that comparison is empty, so relevant diagnostics and changed code disappear from the review inputs.

**Correction:** carry the selected resolved diff through all evidence and verifier stages, including separately captured untracked source files.

### F14 — [P2] Release CI filtering masks crashes and rejects clean success

**Source:** [Bash CI wrapper:115–121][f14bash], [PowerShell wrapper:295–302][f14ps]; [validator success marker:687][f14marker].

The grandfather-exemption steps discard the validator exit status and accept an empty filtered diagnostic list. An unstructured runtime failure can therefore be reported as success. Conversely, they filter `PASSED`/`FAILED`, whereas successful release validation emits `VALID`; a fully clean repository would be rejected as containing an error.

**Current green explained:** existing grandfathered invalid records cause a `FAILED` summary that is filtered out. The observed fixture logs emit `VALID|RECORDS=4` and `VALID|RECORDS=1`. No crash was observed in this run.

**Correction:** retain exit status and summary, recognize `VALID`, reject crashes/unrecognized output, and exempt only the explicitly allowed diagnostics.

### F15 — [P2] An approved release without its evidence chain passes strict validation

**Source:** [Bash:680][f15bash], [PowerShell:457–466][f15ps]; [existing approval fixture][approvalfixture].

A source walkthrough using only the valid fixture's approved-release record satisfies its individual fields. Bash skips cross-record checks when no evaluation exists. PowerShell suppresses orphan-ID checks when the evaluation-ID list is empty. Both therefore reach success without the evaluation, candidate, or QA records.

**Correction:** require every non-evaluation artifact to resolve a canonical evaluation and enforce approved-release linkage even when the evaluation set is empty.

**Coverage gap:** the release property harness uses a copied consistency model, rather than invoking the production validator, so its green result does not cover this boundary.

### F16 — [P2] LSP validators invent a changed line for deletion-only hunks

**Source:** [Bash:88–94][f16bash], [PowerShell:59–63][f16ps].

Both parsers change a new-side count of zero to one. A deletion-only hunk such as `@@ -10 +9,0 @@` consequently permits citation of new-side line 9 despite containing no new-side changed lines.

**Correction:** skip zero-count new-side ranges. Default to one only when the count is omitted.

### F17 — [P2] The environment recipe fails in Next.js browser code

**Source:** [docs/recipes/env-validation.md:47–58][f17].

The shared singleton passes the entire `process.env` object to its client schema. Next.js only inlines direct public-variable references; indirect object lookups are not inlined. Importing this singleton in browser code therefore fails validation despite configured public variables. [Official Next.js guidance][nextenv].

**Correction:** build the client input from explicit `process.env.NEXT_PUBLIC_*` references and separate it from server-only validation.

### F18 — [P2] The Stripe adaptation does not match the published signature verifier

**Source:** [generic verifier:41–49][f18verify], [pipeline:71][f18pipeline], [Stripe adaptation:103–106][f18adapter].

The framework adaptation obtains `stripe-signature`, while the canonical pipeline expects a bare SHA-256 hex digest over the body. Stripe supplies a timestamp/signature header and signs timestamp plus body; passing that header into the shown pipeline rejects valid deliveries. The adaptation leaves verification as a placeholder without supplying the required different scheme.

**Correction:** show Stripe's `webhooks.constructEvent(rawBody, signature, secret)` adapter and clearly name the scheme supported by the generic helper. [Official Stripe signature documentation][stripe].

### F19 — [P2] The Cobalt preset focus ring cannot meet contrast on white

**Source:** [templates/design-tokens-spec.md:121–129][f19].

The preset uses a 35%-opaque ring on a white card. If adopted as the sole authored focus cue, it cannot reach 3:1 under standard sRGB compositing: even black at that opacity reaches only 2.44154:1; the specified cobalt is lighter. This remains after the default dark palette was corrected.

**Correction:** provide an opaque, verified token or another qualifying focus indicator. The requirement applies to the authored indicator against adjacent colors; this is not a claim that a rendered UI was examined. [W3C non-text contrast guidance][wcag].

### F20 — [P2] npm publishing selects an unsupported Node version

**Source:** [release-npm.yml:59–80][f20].

The workflow selects Node 20, then installs npm 11 for trusted publishing. Both its own comment and [official npm prerequisites][npmtrusted] require Node 22.14.0 or newer. Updating npm alone does not meet the Node requirement.

**Correction:** select a supported Node version and validate both runtime and CLI versions. Publishing was not executed during this audit; this is a verified configuration incompatibility, not a claim of an observed publish failure.

### F21 — [P2] Manual publishing can label branch wrapper code as another release

**Source:** [release-npm.yml checkout:25–31][f21checkout], [version assignment:105–113][f21version]; [smoke script:25–43][f21smoke].

A manual run accepts a tag but checks out the selected workflow branch. It assigns that tag's version to the branch's wrapper and publishes it. The smoke step directly extracts/materializes the tag and never executes the wrapper being published, so wrapper drift goes undetected.

**Impact:** the published wrapper's source can differ from the tag it claims to mirror. Its installed kit download still targets the requested tag; this does not imply the wrong kit version is installed.

**Correction:** publish the wrapper from the resolved tag and exercise that wrapper in the smoke path.

### F22 — [P2] Fixture scores are still presented as empirical host results

**Source:** [docs/HOST-CONFORMANCE.md:48–64][f22]; [public evaluation link:36][f22eval]; [probe-pack results:65–67][f22pack].

The document now correctly says live captures are pending and labels the matrix as staged fixtures. Nevertheless, it gives named host versions overall PASS percentages, makes claims about Claude/Cursor runtime behavior, and is still linked as an empirical cross-host matrix. No published full live captures support those claims. The explicit secret-hygiene caveat is good but does not turn formatting fixtures into live host evidence.

**Correction:** present these as scorer/fixture validation only; mark the three hosts untested for runtime fidelity, remove empirical host conclusions, and align inbound links until maintainer captures with model/version/run provenance exist. This finding does not allege fabrication or intent.

## Earlier review corrections present

At the audited revision:

- Release baseline instructions/templates now source the predecessor's Approved Release Candidate Commit.
- Refresh-token rotation requires family identity and revokes reused families; the verification helper extracts the published recipe instead of an independent copy.
- Sync allows an explicit authorized profile patch; PR test-count instructions respect verification applicability.
- The default dark focus ring was restored, and Dialog motion classes are gated with `motion-safe:`.
- Host-conformance baseline SHA and probe-pack directive figures are corrected; unsupported registry entries are clarified. The remaining issue is the empirical presentation in F22.

## Lower-priority maintenance

- [ship.md:194][shipbaseline] still says evidence evaluates against an immutable `v1.0.0` baseline, while the internal procedure correctly requires the latest complete approved release. Align this sentence to avoid conflicting release instructions.
- [BEHAVIORAL-EVAL.md:3][evalcount] says 16 scenarios/self-tests; current CI reports 18. Refresh current counts while retaining clearly identified historical baseline results.

These are not included in the 22 retained findings.

## Coverage and limitations

Five independent source lanes examined installation/distribution, lifecycle/state contracts, security/authority, domain workflows/recipes/design templates, and CI/validators. Parent review covered release governance and public evidence claims. The inventory contained 922 entries, including extensive fixtures. This was a broad risk-focused review, not a claim that every fixture or every possible execution path was evaluated.

[Main CI run 36732021139][ci] passed at the exact reviewed SHA. Both [Linux][linuxjob] and [Windows][windowsjob] checkout logs confirm that SHA. They reported 367 documentation contracts, 18 behavioral fixture self-tests, 7 LSP fixtures and 6 reference fixtures passing, alongside execution/release fixtures, property suites, reference checks and token gates.

The local command tool returns `Failed to create unified exec process: No such file or directory (os error 2)` before starting a process. No local installer, validator, recipe, browser, live host, or release publishing execution is claimed. Existing remote CI is separately observed execution and does not prove the untested scenarios above. No tests were added or run for this audit.

Suggested correction order: F01/F02; installer preservation and boundary issues; CI/release linkage; review/authority contracts; canonical recipes and focus preset; publishing and evidence presentation. Validate each correction on its matching platform or host before treating it as closed.

[f01]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.ps1#L706
[f02]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/commit.md#L89
[f03]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/commit.md#L94
[sensitivepaths]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/harness-security-paths.txt#L5
[f04discovery]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L578
[f04bash]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L756
[f04ps]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.ps1#L754
[f05]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L613
[f06args]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L78
[f06loop]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L593
[f07bash]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L364
[f07ps]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.ps1#L369
[f07validation]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L698
[f08flag]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.ps1#L80
[f08override]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.ps1#L150
[f09]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/isolate-worktree.ps1#L71
[psnative]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-7.6#psnativecommanduseerroractionpreference
[f10]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/init.sh#L717
[f11pre]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/pr.md#L13
[f11]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/pr.md#L36
[f12]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/protocols/subagent-delegation.md#L125
[f12bash]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/isolate-worktree.sh#L77
[authority]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/protocols/code-quality-gate.md#L130
[f13]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/review.md#L53
[f13verifier]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/review.md#L301
[f14bash]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/.github/workflows/ci.yml#L115
[f14ps]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/.github/workflows/ci.yml#L295
[f14marker]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/validate-release-records.sh#L687
[f15bash]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/validate-release-records.sh#L680
[f15ps]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/validate-release-records.ps1#L457
[approvalfixture]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/tests/fixtures/release-records/valid/docs/releases/approved-release.md
[f16bash]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/validate-lsp-evidence.sh#L88
[f16ps]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/scripts/validate-lsp-evidence.ps1#L59
[f17]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/recipes/env-validation.md#L47
[nextenv]: https://nextjs.org/docs/pages/guides/environment-variables#bundling-environment-variables-for-the-browser
[f18verify]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/recipes/webhook-idempotency.md#L41
[f18pipeline]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/recipes/webhook-idempotency.md#L71
[f18adapter]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/recipes/webhook-idempotency.md#L103
[stripe]: https://docs.stripe.com/webhooks/signature
[f19]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/templates/design-tokens-spec.md#L121
[wcag]: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html#relationship-with-focus-visible
[f20]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/.github/workflows/release-npm.yml#L59
[npmtrusted]: https://docs.npmjs.com/trusted-publishers/
[f21checkout]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/.github/workflows/release-npm.yml#L25
[f21version]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/.github/workflows/release-npm.yml#L105
[f21smoke]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/package/test/smoke.sh#L25
[f22]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/HOST-CONFORMANCE.md#L48
[f22eval]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/BEHAVIORAL-EVAL.md#L36
[f22pack]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/internal/host-conformance-pack/README.md#L65
[shipbaseline]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/workflows/ship.md#L194
[evalcount]: https://github.com/lowqualityloey/promptkit-os/blob/61e7e36584468cd8e95de8c29e358eea49a72d52/docs/BEHAVIORAL-EVAL.md#L3
[ci]: https://github.com/lowqualityloey/promptkit-os/actions/runs/36732021139
[linuxjob]: https://github.com/lowqualityloey/promptkit-os/actions/runs/36732021139/job/109943868914
[windowsjob]: https://github.com/lowqualityloey/promptkit-os/actions/runs/36732021139/job/109943869235

