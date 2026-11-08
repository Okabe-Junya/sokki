#!/bin/sh
# Notarizes and staples the app when Apple notary credentials are configured;
# otherwise skips. Notarization accepts only Developer ID signatures made with
# the hardened runtime and a secure timestamp.
#
# Usage: notarize.sh <app>
# Environment: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD
set -eu

app=$1

if [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_TEAM_ID:-}" ] || [ -z "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]; then
  echo "Notarization skipped: APPLE_ID, APPLE_TEAM_ID and APPLE_APP_SPECIFIC_PASSWORD are not all set"
  exit 0
fi

zip=$(mktemp -d "${RUNNER_TEMP:-/tmp}/notarize.XXXXXX")/app.zip
ditto -c -k --keepParent "$app" "$zip"
xcrun notarytool submit "$zip" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" --wait
xcrun stapler staple "$app"
