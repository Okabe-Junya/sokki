#!/bin/sh
# Packs the app into a disk image next to a shortcut to /Applications, so
# installing is one drag.
#
# Usage: make-dmg.sh <app> <output.dmg> [identity]
#   identity   signs the image when given; the app inside keeps its own signature.
set -eu

app=$1
dmg=$2
identity=${3:-}

staging=$(mktemp -d "${TMPDIR:-/tmp}/dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT
# mktemp makes the directory private, and it becomes the root of the volume.
chmod 755 "$staging"

# ditto keeps the signature and the stapled notarization ticket intact.
ditto "$app" "$staging/$(basename "$app")"
ln -s /Applications "$staging/Applications"

rm -f "$dmg"
hdiutil create -quiet -volname "$(basename "$app" .app)" -srcfolder "$staging" -format UDZO "$dmg"

if [ -n "$identity" ]; then
  codesign --sign "$identity" --timestamp "$dmg"
fi
echo "$dmg"
