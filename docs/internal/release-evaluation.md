# PromptKit OS Internal Release Evaluation Procedure

> **Internal Only**: This evaluation procedure applies only to the `promptkit-os` repository. It does not impose Conventional Commit, SemVer, release-note, tag, remote, publication, deployment, or rollback requirements on repositories that consume PromptKit OS. Refer to [`workflows/ship.md`](../../workflows/ship.md) for standard workflow usage.

### PromptKit OS Internal Release Evaluation

This evaluation applies only to the Better-PromptKit repository. It is a documentation record for deriving and reviewing a release candidate from Better-PromptKit evidence. It does not impose Conventional Commit, SemVer, release-note, tag, remote, publication, deployment, or rollback requirements on repositories that consume Better-PromptKit.

The evaluation must remain separate from production execution. A calculated version is a preliminary candidate, not an Approved Release Version. A passing validator, CI result, checkpoint handoff, empty blocker list, or completed QA review does not create a tag, hosted release, published changelog, remote operation, deployment, or rollback authorization.

#### 1. Establish Evaluation Identity and the Version Source of Truth

Create one stable **Evaluation ID** for every release evaluation and use that exact identifier in the evaluation, candidate, QA/Reviewer review, release notes, draft changelog entries, and Approved Release Record. Record the accountable Release Coordinator and the date the evaluation was opened.

Select the prior approved baseline before inspecting impact:

- The **Version Source of Truth** is the latest complete Approved Release Record. Read its **Approved Release Version** and **Approved Release Candidate Commit**, and record that candidate commit as the new evaluation's **Prior Approved Release Commit** to serve as the exclusive baseline for the next evaluation.
- Never use a preliminary candidate, checkpoint handoff, unapproved tag, or draft changelog as the Version Source of Truth.
- Record the prior approved version, prior approved release commit (sourced from the predecessor's Approved Release Candidate Commit), and the source record path or identifier. If there is no prior Approved Release Record, mark the evaluation `First Release: true` and record the all-history starting point used for review.
- The baseline is immutable evidence for this evaluation. Do not rewrite it to make a range or candidate appear consistent.

#### 2. Define the Candidate-Inclusive Release Range

Record the range as reproducible boundaries before classifying commits:

| Field | Required record |
| :--- | :--- |
| **Release Range start** | The prior approved release commit as an exclusive boundary, or the recorded all-history start for a First Release. |
| **Release Range end** | The selected Better-PromptKit revision under evaluation. |
| **Release Candidate Commit** | The exact commit identifier at the Release Range end; it is inclusive and must be present in the ordered range list. |
| **Ordered range commits** | Every reviewed commit from the start boundary through and including the candidate, in a reproducible order. |

For a normal release, the Release Range contains commits after the prior approved baseline and through the inclusive Release Candidate Commit. For a First Release, the range contains the recorded Better-PromptKit history through the inclusive candidate. Do not classify commits outside the recorded range.

Run a candidate-membership consistency check before deriving a version:

1. Confirm the Release Candidate Commit is present exactly once in the ordered range.
2. Confirm it is the inclusive end of the range and is reachable from the selected Better-PromptKit history.
3. Confirm the recorded prior boundary, when present, matches the Approved Release Version and Approved Release Candidate Commit supplied by the latest complete Approved Release Record.
4. Mark the evaluation blocked if the candidate is absent, duplicated, outside the boundaries, or associated with a different Evaluation ID. A failed check never substitutes a different commit automatically.

#### 3. Normalize the Effective Change Set

Normalize the complete Release Range before calculating SemVer or deriving release notes. Record the shape, eligibility, evidence reference, representative, and resulting impact for every reviewed item. Candidate calculation and note derivation must consume the same ordered **Effective Change Set**.

Apply these rules:

- **Merge Commit:** Do not classify the merge node as an independent public change. Review the eligible non-merge commits brought into the range and retain their evidence once.
- **Squash Commit:** Treat the squash as one Eligible Commit. Classify it from its combined Contract Impact Evidence rather than classifying each squashed contribution separately.
- **Duplicate Change Group:** Collapse equivalent changes to one effective representative, one evidence record, one candidate contribution, and one public note. Record the duplicate members and representative.
- **Fully cancelling Revert Pair:** Remove the original change and its complete revert from the Effective Change Set. They contribute no SemVer impact and no Public Release Note.
- **Partial Revert:** Do not treat a revert as a full cancellation when the resulting behavior leaves a new public contract effect. Classify the resulting contract from the new evidence and retain its effective residual impact and note.
- **Unresolved or unsupported history:** Record the affected commits and a blocker instead of silently guessing, excluding evidence, or allowing a label to determine impact.

The normalized result must state which merge, squash, duplicate-group, full-revert, and partial-revert rules were applied. The same normalized Effective Change Set is the sole input to both SemVer candidate calculation and filtered release-note derivation.

#### 4. Derive an Evidence-Driven SemVer Candidate

Determine impact from Contract Impact Evidence describing the user-observable Public PromptKit Contract, not from the Conventional Commit type, scope, or subject alone. `feat`, `fix`, and `perf` labels are informative history fields; they do not determine the increment.

| Effective Contract Impact Evidence | Candidate impact |
| :--- | :--- |
| **User-Facing Additive Contract Change** | `minor` |
| **User-Facing Corrective Contract Change** | `patch` |
| **Breaking Contract Change with Migration and Upgrade Guidance** | `major` |
| **Breaking Contract Change without Migration and Upgrade Guidance** | `blocked`; no approvable major candidate until guidance is supplied and reviewed |
| **Maintenance Commit** with an explicit declaration of no intentional Public PromptKit Contract change | `none`; no SemVer increment |

Select the greatest effective impact in the normalized range using the precedence **`major > minor > patch`**. `none` does not increase a version. A missing breaking-change guidance record is a named blocker even when the commit is otherwise classified as breaking. Do not use a `docs`, `test`, `refactor`, `style`, or `chore` label to override evidence or to manufacture public impact.

For a First Release, record the absence of a prior Approved Release Record and the complete first-release range. When that effective range contains at least one additive public contract change, the candidate core version is **`1.0.0`**. This is a candidate rule, not approval and not permission to create a `v1.0.0` tag. Continue to record the supporting effective commits and rationale.

The **SemVer Candidate Record** must contain:

- Candidate core version and display candidate version.
- The calculated impact and the greatest-impact rationale, including the First Release `1.0.0` rule when applicable.
- **Status: preliminary**. Never use `approved` or equivalent wording for this record.
- The exact **Release Candidate Commit** and the supporting Eligible Commits from the Effective Change Set.
- The **Evaluation ID**, prior approved baseline or First Release status, and Release Range boundaries.
- An optional **Prerelease Identifier** and the resulting display candidate, such as a core candidate plus `-alpha.1` or `-rc.1`.
- Any prerequisite, guidance, QA, or consistency blocker.

A prerelease identifier changes the display candidate only; it does not change the core impact calculation or grant approval. When a prerelease is promoted, record the same Evaluation ID, Release Candidate Commit, Release Range, supporting effective commits, and candidate rationale. The promoted Approved Release Version may omit the Prerelease Identifier only after an explicit Release Coordinator approval record; preserve the prerelease provenance and explain any difference between the preliminary candidate and approved version.

#### 5. Handle an Empty Eligible Range Explicitly

After normalization, set **Empty eligible range: true** when no effective Eligible Commit has a SemVer-impacting public contract change. Maintenance-only history, a fully cancelling revert pair, or a range containing only excluded merge nodes can produce this state.

An empty eligible range is not an automatic patch release and is not an implicit approval. The Release Coordinator must record one explicit decision:

- **Defer:** no release is approved; record the reason and the next evaluation or trigger.
- **Approve a documented no-contract-change release:** record why a release with no public-contract increment is needed, the approved version rationale, QA result, and all consistency results.

If neither decision is recorded, the evaluation remains blocked. No empty-range result authorizes a tag, hosted release, changelog publication, remote action, deployment, or rollback.

#### 6. QA/Reviewer Release-Evaluation Review

Before approval, the QA/Reviewer must review and record a result under the same Evaluation ID. The review must cover:

- **Range boundary review:** prior baseline or First Release start, Release Range end, inclusive Release Candidate Commit, ordered range, and candidate-membership consistency.
- **Classification review:** eligibility, Contract Impact Evidence, Maintenance Commit declarations, breaking Migration and Upgrade Guidance, and the fact that labels do not determine SemVer impact.
- **Normalization review:** merge, squash, duplicate-group, fully cancelling revert, and partial-revert treatment, including the resulting Effective Change Set.
- **Precedence review:** confirmation that the preliminary candidate uses the greatest effective impact, with `major > minor > patch`, and applies the First Release `1.0.0` additive rule when applicable.
- **Blocker review:** every missing evidence item, missing breaking guidance, failed consistency check, unsupported classification, unresolved scope issue, and open correction with an owner and disposition.
- **Release-note coverage review:** every effective public contract change has exactly one supported Public Release Note, duplicate and full-revert handling is reflected, breaking notes include guidance, and every note maps back to evidence in the same Effective Change Set.

Record the reviewer identity, review date, findings, blocker status, and correction/re-review result. A failed or incomplete QA/Reviewer result keeps the evaluation unapproved even if the candidate version is calculable.

#### 7. Derive Public and Maintenance Release Notes Without Publishing

Derive notes only from the normalized Effective Change Set:

- **Public Release Notes** describe each distinct effective user-observable Public PromptKit Contract change once, identify the affected contract and before/after behavior, and include Migration and Upgrade Guidance for breaking changes.
- **Maintenance Release Notes** are clearly labeled `Maintenance` and describe effective maintenance classifications that declare no intentional public-contract change. They do not claim a SemVer increment.
- A duplicate change group produces one representative note. A fully cancelling Revert Pair produces no public note. A Partial Revert produces a note only when new evidence shows a resulting contract impact.
- Record note sources, evidence references, reviewer coverage, and the shared Evaluation ID.

Create explicit **draft Changelog Entries** for the reviewed Public Release Notes and Maintenance Release Notes. Every draft entry must be labeled **unpublished** or **not published** and must state that publication is a separate human decision. Drafting a changelog entry does not write to a hosted changelog, publish a file, perform a remote action, or authorize a release.

#### 8. Create the Approved Release Record Only After Human Approval

The Approved Release Record is an internal decision record, not an automatic release operation. It must be created only after the Release Coordinator has reviewed the candidate and QA/Reviewer result and made an explicit decision. Include all of these fields:

| Field | Required content |
| :--- | :--- |
| **Evaluation ID** | The same stable identifier used by the evaluation, candidate, QA review, notes, draft changelog entries, and consistency results. |
| **Approved Release Version** | The final version explicitly approved by the Release Coordinator. |
| **Approved Release Tag** | The tag string approved for that version; it must encode the Approved Release Version. Record it without creating the tag. |
| **Release Candidate Commit** | The exact candidate revision from the evaluation and candidate record. |
| **Release Range boundaries** | The reviewed start, end, ordered commits, and inclusive candidate-membership result. |
| **SemVer Candidate and rationale** | The preliminary candidate, supporting evidence, precedence result, and a non-empty rationale for any approved-version difference. |
| **QA/Reviewer result** | Range, classification, normalization, precedence, blocker, and note-coverage findings, including final correction status. |
| **Public and Maintenance Release Notes** | The reviewed effective notes and their evidence references. |
| **Approval decision, date, and coordinator** | Explicit approved, deferred, or no-contract-change decision, the Release Coordinator identity, and decision date. |
| **Release-consistency results** | Field-level pass/fail results and any resolved findings. No failed result may be represented as approved. |
| **External-action decisions** | Separate decisions for tag creation, hosted release creation, changelog publication, remote operations, deployment, and rollback. |

An approved version must equal the preliminary candidate unless the record contains a specific rationale for the difference. Approval is never inferred from a candidate, QA pass, or completed record field. A deferred decision remains deferred and cannot be described as an Approved Release Version.

#### 9. Run Cross-Record Consistency Checks

Before treating the Approved Release Record as complete, record the result of each check:

- **Shared Evaluation ID:** evaluation, range, candidate, QA/Reviewer review, Public Release Notes, Maintenance Release Notes, draft Changelog Entries, approval, and consistency results use one Evaluation ID.
- **Candidate-in-range:** the exact Release Candidate Commit is present once and inclusively at the end of the recorded Release Range.
- **Tag/version alignment:** the approved tag string encodes exactly the Approved Release Version. A proposed tag is evidence only until separately approved and created.
- **Version precedence:** the Approved Release Version does not regress below the Version Source of Truth under SemVer precedence, unless a documented and separately reviewed policy decision explicitly explains the outcome.
- **Approval and rationale:** the Release Coordinator, decision date, decision, and approval rationale are present; a difference from the preliminary candidate has a non-empty explanation.
- **QA and note linkage:** the QA/Reviewer result covers the same range and Effective Change Set, and every reviewed note is linked to evidence and the same Evaluation ID.
- **Consistency outcome:** each failure names the artifact, field, owner, and correction. A failed check blocks approval and never triggers corrective Git, remote, publication, deployment, or rollback activity.

#### 10. Keep External Release Actions Human-Only and Separate

The Release Coordinator must make separate, explicit human-approved decisions for each action. Recording one action does not imply permission for another:

- Create the Git release tag.
- Create the hosted release.
- Publish the changelog or any release notes.
- Perform remote operations, including pushing release-related refs.
- Trigger or authorize production deployment.
- Execute or authorize a production rollback.

`pk:ship` records the evaluation, evidence, QA result, approval decision, and requested action boundaries. It must not automatically run tag commands, push commands, hosted-release commands, changelog publication, deployment, or rollback. The existing production-safety guidance, release checklist, and Steps 3 through 5 remain in force after this evaluation, and each external action still requires its own human Release Coordinator decision.
