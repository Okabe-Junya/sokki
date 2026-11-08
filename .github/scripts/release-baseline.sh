#!/bin/sh
# Prints the comparison baseline for release-drafter as a GitHub Actions output.
# release-drafter v7 drafts "No changes" when the repository has no published
# release yet, so until the first release the baseline is the root commit; after
# that the output stays empty and release-drafter uses the last published release.
#
# Usage: release-baseline.sh <owner/repo>
# Environment: GH_TOKEN, GITHUB_OUTPUT
set -eu

repo=$1

published=$(gh release list --repo "$repo" --exclude-drafts --exclude-pre-releases --limit 1 --json tagName --jq 'length')
if [ "$published" -eq 0 ]; then
  from=$(git rev-list --max-parents=0 HEAD)
  echo "No published release yet; drafting from the root commit $from"
else
  from=""
fi
echo "from=$from" >> "$GITHUB_OUTPUT"
