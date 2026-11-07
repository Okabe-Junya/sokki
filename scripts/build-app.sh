#!/bin/sh
# Builds Koe with SwiftPM, assembles build/Koe.app and signs it.
#
# Usage: build-app.sh [identity]
#   identity   name or SHA-1 from `security find-identity -v -p codesigning`;
#              falls back to $CODESIGN_IDENTITY, then "-" (ad-hoc). Ad-hoc
#              signatures change on every build, so macOS forgets the app's
#              privacy permissions each time; use a stable identity for daily use.
# Environment:
#   CONFIGURATION  debug | release (default release)
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
configuration=${CONFIGURATION:-release}
identity=${1:-${CODESIGN_IDENTITY:--}}
app="$root/build/Koe.app"

swift build --package-path "$root" -c "$configuration" --product Koe
bin_dir=$(swift build --package-path "$root" -c "$configuration" --show-bin-path)

version=$(git -C "$root" describe --tags --always --dirty 2>/dev/null || echo 0.0.0)
build=$(git -C "$root" rev-list --count HEAD 2>/dev/null || echo 1)

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Koe" "$app/Contents/MacOS/Koe"
sed -e "s/__VERSION__/${version#v}/" -e "s/__BUILD__/$build/" "$root/scripts/Info.plist" > "$app/Contents/Info.plist"

codesign --force --sign "$identity" --identifier dev.okabe.koe "$app"

if [ "$identity" = "-" ]; then
  echo "warning: ad-hoc signed; privacy permissions will reset on the next build" >&2
fi
echo "$app"
