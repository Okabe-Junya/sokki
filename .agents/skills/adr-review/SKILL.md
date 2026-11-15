---
name: adr-review
description: >-
  Reviews a Sokki branch or pull request against the Accepted ADRs in docs/adr
  with a fresh read-only reviewer, fixes confirmed conflicts, and records the
  result as the ADR self-review line of the PR body. Use before marking a PR
  ready for review when it changes Sources/, Package.swift, scripts/, the
  release workflow, entitlements, or Info.plist; when a PR body still says the
  ADR self-review is pending; or when asked whether a change conflicts with an
  ADR (ADR レビュー, ADR と矛盾していないか). Skip docs-only (outside
  docs/adr), test-only, and lint/CI-config changes.
---

# ADR review for Sokki

## Decide whether to run

Run it when the change set touches `Sources/`, `Package.swift`, `scripts/`,
`.github/workflows/release.yaml`, `.github/scripts/`, entitlements, or
`Info.plist`. Skip it for changes confined to `Tests/`, lint or CI config, or
prose outside `docs/adr/`, and write nothing in the PR body.

If the change implements an ADR that `git ls-tree --name-only origin/main
docs/adr/` does not list yet, its ADR PR is still open. Do not review yet:
write `ADR self-review: pending (runs after #<ADR PR> merges).` and stop. The
ADR PR merges first.

## Resolve the inputs

1. **Corpus**: `git fetch origin`, then `git rev-parse origin/main`. ADRs are
   always read from `main`, also for stacked PRs.
2. **Base**: read `gh pr view <N> --json baseRefName` (no PR yet: `main`).
   For `main`, use `git merge-base <corpus> HEAD`. For any other branch (a
   stacked PR), use `git rev-parse origin/<baseRefName>`, so the parent PR's
   commits are not reviewed twice. Never diff against the corpus itself:
   commits already on `main` would read as reverted.
3. **Duplicate ADR commits**: the repository merges by squash only, so a branch
   cut before its ADR PR merged still carries the original ADR commit. Rebase
   onto `origin/main` and drop that commit before reviewing; a diff that adds
   an ADR file already on `main` is this case.
4. **Untracked files**: `git ls-files --others --exclude-standard`.
5. **Binding ADRs**: files in `docs/adr/` at the corpus whose `## Status`
   section starts with `Accepted`. `Superseded by ADR N …` records are context
   only.

## Run the review

Make at most three passes. For each pass:

1. Start a fresh subagent with no edit tools, or tell it not to edit, commit,
   push, or comment. Give it only:
   - the policy, read from the corpus rather than from the working tree, so a
     change cannot weaken its own review:
     `git show <corpus>:.agents/skills/adr-review/review-policy.md`
   - the corpus and base SHAs, and the instruction to read every ADR with
     `git show <corpus>:docs/adr/<file>` and the change with
     `git diff --find-renames <base>`
   - the untracked-file list, and the PR title and body when a PR exists,
     with any existing `ADR self-review:` line removed so an earlier verdict
     does not anchor the new one.

   Do not pass a summary of the diff, the implementation rationale, or
   suspected findings.
2. Accept only the JSON object the policy defines. Retry malformed output once;
   if it fails again, report the review as unavailable.
3. Verify each finding: the quote appears verbatim in the corpus ADR, and the
   named path is in the change set. Drop findings that fail either check.
4. Stop on `not_applicable`, or on `no_conflict` once no verified findings
   remain.
5. Fix verified findings that fall within the task. Run `task check`, then start
   the next pass with a new reviewer. Run only one `task check` at a time on a
   machine: `PasteSessionTests` share one named system pasteboard, so
   concurrent runs fail each other.

Never clear a finding by editing an ADR in the same change. The corpus is
`main`, so the finding stays. A changed decision gets a new superseding ADR in
its own PR, which merges first, as `AGENTS.md` requires. Then rebase and
review again.

## Record the result

Put one line at the end of the PR body's `## Why` section, replacing any
earlier `ADR self-review:` line:

- `ADR self-review: no conflict.`
- `ADR self-review: not applicable.`
- `ADR self-review: needs human review.`, followed by one bullet per
  unresolved finding (ADR number, quote, path, reason).

After three passes with findings left, use the third form; never report a
clean review that did not happen.
