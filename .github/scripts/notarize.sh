#!/bin/sh
# Notarizes an app or a disk image with an App Store Connect API key and staples
# the ticket, so a downloaded copy opens without a Gatekeeper prompt.
#
# Usage: notarize.sh <app or dmg>
# Environment:
#   APPLE_API_KEY_P8      contents of the AuthKey_<id>.p8 file
#   APPLE_API_KEY_ID      its key ID
#   APPLE_API_ISSUER_ID   the issuer ID shown above the key list
set -eu

target=$1

if [ -z "${APPLE_API_KEY_P8:-}" ] || [ -z "${APPLE_API_KEY_ID:-}" ] || [ -z "${APPLE_API_ISSUER_ID:-}" ]; then
  echo "::error::Secrets APPLE_API_KEY_P8, APPLE_API_KEY_ID and APPLE_API_ISSUER_ID are not all set. Refusing to ship a build that is not notarized." >&2
  exit 1
fi

dir=$(mktemp -d "${RUNNER_TEMP:-/tmp}/notarize.XXXXXX")
trap 'rm -rf "$dir"' EXIT
key="$dir/AuthKey.p8"
printf '%s' "$APPLE_API_KEY_P8" > "$key"

# The notary service takes archives and disk images, not bare bundles.
case $target in
  *.app)
    upload="$dir/app.zip"
    ditto -c -k --keepParent "$target" "$upload"
    ;;
  *) upload=$target ;;
esac
xcrun notarytool submit "$upload" --key "$key" --key-id "$APPLE_API_KEY_ID" \
  --issuer "$APPLE_API_ISSUER_ID" --wait --output-format json > "$dir/result.json"
cat "$dir/result.json"

if ! grep -q '"status" *: *"Accepted"' "$dir/result.json"; then
  id=$(sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' "$dir/result.json")
  xcrun notarytool log "$id" --key "$key" --key-id "$APPLE_API_KEY_ID" --issuer "$APPLE_API_ISSUER_ID" || true
  exit 1
fi

xcrun stapler staple "$target"
xcrun stapler validate "$target"
