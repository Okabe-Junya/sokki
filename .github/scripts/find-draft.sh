#!/bin/sh
# Resolves the release to publish and writes its tag as a GitHub Actions output.
# With no tag given, the repository must have exactly one draft release (the one
# release-drafter maintains).
#
# Usage: find-draft.sh <owner/repo> [tag]
# Environment: GH_TOKEN, GITHUB_OUTPUT
set -eu

repo=$1
tag=${2:-}

if [ -z "$tag" ]; then
  tag=$(gh release list --repo "$repo" --json tagName,isDraft \
    --jq '[.[] | select(.isDraft)] | if length == 1 then .[0].tagName else error("expected exactly one draft release, found \(length)") end')
fi
echo "Publishing $tag"
echo "tag=$tag" >> "$GITHUB_OUTPUT"
