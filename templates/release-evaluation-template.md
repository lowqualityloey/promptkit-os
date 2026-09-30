# PromptKit OS Release Evaluation: [Evaluation ID]

<!-- Replace the example anchor ID with the immutable Release ID before saving the record. -->
<a id="RELEASE-release-slug"></a>

> **Developer-friendly fill-in guide:** Mark each record field **Required**, **Optional**, or **Not applicable** in the evaluation you create. Required fields establish reproducible evidence; Optional fields add context when available; Not applicable fields need the permitted `N/A` value and a reason when the prompt requests one. Use concise evidence such as an exact commit, stable record link, reviewer/date, or one-line decision. Example: `Candidate-Inclusive Membership Result: Pass` with the ordered range link is clearer than `checked`.
>
> **Status map:** Evaluation identity, bounded range, normalized history, preliminary candidate, QA review, release-note coverage, approval decision, consistency results, blockers, and the next action are **Required when this evaluation reaches that section**. Consumer Repository Applicability is **Not applicable** by design. Candidate and approval values remain separate: a preliminary candidate is not an approved release, and a pending or failed check must remain visible.
>
> **Acronym guide:** `SemVer` means Semantic Versioning; `QA` means Quality Assurance; and `N/A` means Not applicable. These explanations improve readability only; the evaluation remains documentation-first and never creates tags, publishes notes, performs remote operations, deploys, or rolls back.

<!-- This is a documentation-first internal evaluation record. It records a bounded range, normalized evidence, a preliminary SemVer Candidate, QA review, and a separate approval decision. It does not invoke Git, remote services, tag creation, hosted-release creation, changelog publication, deployment, or rollback. -->

<!-- This evaluation supplies candidate and QA evidence; the canonical release linkage fields live in the existing `docs/releases/<release>.md` release checklist. -->

## 1. Evaluation Identity and Scope

- **Record Type**: `Release Evaluation`
- **Release ID [Required]**: `RELEASE-<release-slug>`
- **Canonical Release Record Path [Required]**: `docs/releases/<release>.md`
- **Evaluation ID**: `[EVAL-YYYY-MM-DD-slug]`
- **Repository Scope**: `PromptKit OS only`
- **Evaluation Owner / Role**: `[Release Coordinator, Planner/Architect, or QA/Reviewer]`
- **QA/Reviewer**: `[name or role]`
- **Release Coordinator**: `[name or role, or N/A before approval]`
- **Created**: `[YYYY-MM-DD HH:MM UTC]`
- **Evaluation Status**: `[preliminary | blocked | deferred | approved]`
- **Consumer Repository Applicability**: `N/A`; this evaluation does not impose commit, versioning, release-note, tag, remote, or publication policy on repositories that consume PromptKit OS.
- **Evaluation Objective**: `[why this release candidate is being evaluated]`

## 2. Prior Baseline and Bounded Release Range

- **Latest Approved Release Record**: `[record path or N/A]`
- **Version Source of Truth**: `[approved version and Approved Release Candidate Commit from the latest complete approved record, or N/A for First Release]`
- **Prior Approved Release Version**: `[version or N/A]`
- **Prior Approved Release Commit**: `[predecessor's Approved Release Candidate Commit as exclusive baseline commit, or N/A for First Release]`
- **First Release**: `[Yes | No]`
- **Release Range Start**: `[exclusive prior approved commit, recorded all-history start, or N/A]`
- **Release Range End**: `[inclusive Release Candidate Commit]`
- **Release Candidate Commit**: `[exact candidate revision]`
- **Candidate-Inclusive Membership Result**: `[Pass | Fail | Pending]`
- **Range Selection Rationale**: `[explain the baseline, candidate boundary, and reproducible ordered range]`
- **Ordered Range Commit References**: `[ordered non-merge and merge commit references, or linked inventory]`

## 3. Normalized Effective History

Normalize the selected range before deriving a candidate or release notes. Merge commits are not independently classified. Squash commits are classified once from combined evidence. Duplicate groups use one representative. Fully cancelling revert pairs are removed. A partial revert receives new evidence for the resulting contract.

| Order | Commit Reference | Shape | Eligibility | Evidence / Maintenance Reference | Candidate Impact | Effective Representative | Note Disposition |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `[1]` | `[commit]` | `[non-merge | merge | squash | duplicate | revert | modified revert]` | `[Eligible | Excluded]` | `[evidence ID or maintenance declaration]` | `[major | minor | patch | none | blocked]` | `[commit or representative]` | `[Public | Maintenance | Omit | Blocked]` |

- **Excluded Merge Commits**: `[merge references and reason, or None]`
- **Squash Treatment**: `[combined-evidence classification, or None]`
- **Duplicate Change Groups**: `[group, representative, and retained evidence, or None]`
- **Fully Cancelling Revert Pairs**: `[pairs removed from candidate and notes, or None]`
- **Modified Reverts**: `[new evidence and resulting impact, or None]`
- **Effective Change Set Summary**: `[ordered set used by both candidate derivation and release-note derivation]`
- **Empty Eligible Range**: `[Yes | No]`
- **Empty-Range Decision**: `[Release Coordinator decision to defer or approve a documented no-contract-change release, or N/A]`
- **Normalization Blockers**: `[missing evidence, unsupported classification, or None]`

## 4. Preliminary SemVer Candidate

The candidate is always preliminary until a separate Approved Release Record exists. Candidate impact follows Contract Impact Evidence and uses greatest precedence: major, then minor, then patch. Commit labels do not determine impact by themselves.

- **Candidate Status**: `preliminary`
- **Candidate Core Version**: `[major.minor.patch, or N/A while blocked]`
- **Prerelease Identifier**: `[identifier or N/A]`
- **Display Candidate Version**: `[candidate core with prerelease suffix, or N/A]`
- **Greatest Effective Impact**: `[major | minor | patch | none | blocked]`
- **Impact Precedence Rationale**: `[explain the highest effective contract impact in the normalized range]`
- **Supporting Eligible Commits**: `[commit references and evidence IDs]`
- **Candidate Provenance**: `[Release Candidate Commit, range, evaluation ID, and evidence references]`
- **First Release Candidate Rule**: `[If First Release and additive impact exists, record 1.0.0; otherwise N/A]`
- **Prerelease / Promotion Record**: `[candidate suffix and, if promoted, final version without suffix retaining the same candidate commit, or N/A]`
- **Candidate Blockers**: `[breaking guidance, missing evidence, or None]`

## 5. QA/Reviewer Review

- **Range Boundary Result**: `[Pass | Fail | Pending]`
- **Candidate Membership Result**: `[Pass | Fail | Pending]`
- **Eligibility and Maintenance Classification Result**: `[Pass | Fail | Pending]`
- **Complex-History Normalization Result**: `[Pass | Fail | Pending]`
- **SemVer Precedence Result**: `[Pass | Fail | Pending]`
- **Breaking-Guidance Result**: `[Pass | Fail | Pending | N/A]`
- **Every Release Note Has Supporting Contract Impact Evidence**: `[Pass | Fail | Pending]` - `[evidence references for every Public or Maintenance Release Note]`
- **Every Effective User-Observable Contract Change Has Exactly One Public Release Note**: `[Pass | Fail | Pending]` - `[effective change-set and note-coverage references]`
- **QA/Reviewer Findings**: `[findings with evidence references, or None]`
- **Named Release Blockers**: `[blocker, owner, and correction condition, or None]`
- **QA Review Decision**: `[Accepted for coordinator decision | Blocked pending correction | Deferred | N/A]`
- **Coordinator-Handoff Gate**: `Both release-note coverage attestations must be Pass before QA review is accepted for coordinator decision.`
- **Review Date and Attestation**: `[YYYY-MM-DD HH:MM UTC and reviewer]`
- **Re-Review Result**: `[Pass after correction | Not required | Pending | N/A]`

## 6. Filtered Release Notes and Unpublished Changelog Draft

Create one Public Release Note for each distinct effective user-observable Public PromptKit Contract change. Fully cancelled reverts produce no note. Duplicate groups produce one note. Maintenance notes are omitted or placed in a clearly labeled Maintenance section.

### Public Release Notes

| Note ID | Affected Public PromptKit Contract | User-Observable Change | Migration / Upgrade Guidance | Supporting Evidence | Coverage Result |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `[NOTE-1]` | `[contract]` | `[before/after summary]` | `[required guidance or N/A]` | `[evidence ID and commit]` | `[Supported | Missing]` |

### Maintenance Release Notes

- **Maintenance Note Policy**: `[Omitted | Included in a section labeled Maintenance]`
- **Maintenance Notes**: `[maintenance classifications and supporting references, or None]`

### Draft Changelog Entries

- **Changelog State**: `Draft and unpublished`
- **Derived Entries**: `[one entry per Public Release Note or Maintenance Release Note]`
- **Note-to-Changelog Coverage**: `[Pass | Fail | Pending]`
- **Publication Decision**: `Separate human decision required; no publication is performed by this record.`

## 7. Approved Release Record and Decision

These fields remain empty or explicitly not approved until the Release Coordinator records a separate approval decision.

- **Approved Release Record**: `[record path or N/A]`
- **Approved Release Version**: `[version or Not approved]`
- **Approved Release Tag**: `[tag or Not approved]`
- **Approved Release Candidate Commit**: `[exact revision or Not approved]`
- **Approved Release Range**: `[start and inclusive end or Not approved]`
- **Candidate-versus-Approved Comparison**: `[Equal | Different with rationale | Not approved]`
- **Approval Difference Rationale**: `[required when approved version differs from the preliminary candidate, or N/A]`
- **Approval Decision**: `[Approved | Deferred | No-contract-change release approved | Not approved]`
- **Approval Date**: `[YYYY-MM-DD HH:MM UTC or N/A]`
- **Release Coordinator Decision Record**: `[coordinator and approval evidence, or N/A]`

## 8. Release-Consistency Results

| Consistency Check | Result | Evidence / Finding |
| :--- | :--- | :--- |
| Evaluation ID is shared by range, evidence, QA, notes, and approval | `[Pass | Fail | Pending | N/A]` | `[reference]` |
| Release Candidate Commit is in the inclusive range end | `[Pass | Fail | Pending]` | `[reference]` |
| Approved version and tag correspond | `[Pass | Fail | Pending | N/A]` | `[reference]` |
| Approved version does not regress below Version Source of Truth | `[Pass | Fail | Pending | N/A]` | `[reference]` |
| Required approval and rationale are present | `[Pass | Fail | Pending | N/A]` | `[reference]` |
| QA result and release-note coverage are linked | `[Pass | Fail | Pending]` | `[reference]` |
| Empty eligible range has an explicit coordinator decision | `[Pass | Fail | Pending | N/A]` | `[reference]` |

- **Overall Consistency Result**: `[Pass | Fail | Pending | N/A before approval]`
- **Consistency Blockers and Resolution**: `[blocker and correction condition, or None]`

## 9. Separate Human-Only External-Action Decisions

This section records decisions only. It does not execute any action.

- **Tag Creation Decision**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Hosted Release Creation Decision**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Changelog Publication Decision**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Remote Operation Decision**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Deployment Decision**: `[Not requested | Request human decision | Approved separately | Declined]`
- **Rollback Decision**: `[Not requested | Request human decision | Approved separately | Declined]`
- **External-Action Owner and Evidence**: `[Release Coordinator decision record or N/A]`

A preliminary candidate, QA review, checkpoint handoff, or approved record never performs an external action automatically. Tagging, hosted release creation, changelog publication, remote operations, deployment, and rollback remain separate human decisions.

## 10. Blockers and Next Action

- **Open Blockers**: `[named blocker, owner, and resolution condition, or None]`
- **Resume Condition**: `[what must be corrected or approved before the next state, or N/A]`
- **Next Action**: `[Exactly one prioritized action]`
