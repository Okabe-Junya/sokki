#!/bin/sh
# Builds Sokki with SwiftPM, assembles build/Sokki.app and signs it.
#
# Usage: build-app.sh [identity]
#   identity   name or SHA-1 from `security find-identity -v -p codesigning`;
#              falls back to $CODESIGN_IDENTITY, then "-" (ad-hoc). Ad-hoc
#              signatures change on every build, so macOS forgets the app's
#              privacy permissions each time; use a stable identity for daily use.
# Environment:
#   CONFIGURATION  debug | release (default release)
#   VERSION        marketing version to embed; defaults to `git describe --tags`.
#                  The release workflow passes the tag of the draft it publishes.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
configuration=${CONFIGURATION:-release}
identity=${1:-${CODESIGN_IDENTITY:--}}
app="$root/build/Sokki.app"

swift build --package-path "$root" -c "$configuration" --product Sokki
bin_dir=$(swift build --package-path "$root" -c "$configuration" --show-bin-path)

version=${VERSION:-$(git -C "$root" describe --tags --always --dirty 2>/dev/null || echo 0.0.0)}
build=$(git -C "$root" rev-list --count HEAD 2>/dev/null || echo 1)

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Sokki" "$app/Contents/MacOS/Sokki"
sed -e "s/__VERSION__/${version#v}/" -e "s/__BUILD__/$build/" "$root/scripts/Info.plist" > "$app/Contents/Info.plist"

# The Icon Composer document becomes Assets.car, which holds the light, dark, and tinted
# icons, plus an AppIcon.icns for tools that do not read asset catalogs.
# actool exits 0 even when it compiles nothing, so the outputs are checked instead. It skips
# app icons unless a partial Info.plist is requested; scripts/Info.plist already has those keys.
icon_plist="$root/build/icon-info.plist"
icon_log=$(xcrun actool "$root/scripts/AppIcon.icon" --compile "$app/Contents/Resources" \
  --app-icon AppIcon --platform macosx --target-device mac --minimum-deployment-target 26.0 \
  --output-partial-info-plist "$icon_plist" \
  --output-format human-readable-text --errors --warnings 2>&1) || true
rm -f "$icon_plist"
for icon in Assets.car AppIcon.icns; do
  if [ ! -f "$app/Contents/Resources/$icon" ]; then
    echo "error: actool did not produce $icon" >&2
    echo "$icon_log" >&2
    exit 1
  fi
done

# The hardened runtime is required for notarization; signing every build with it keeps
# local builds behaving like releases. Only Apple-issued certificates get a secure
# timestamp, which notarization also requires.
case $identity in
  "Developer ID Application"*) timestamp=--timestamp ;;
  *) timestamp=--timestamp=none ;;
esac
codesign --force --sign "$identity" --identifier dev.junya.sokki \
  --options runtime "$timestamp" --entitlements "$root/scripts/Sokki.entitlements" "$app"

if [ "$identity" = "-" ]; then
  echo "warning: ad-hoc signed; privacy permissions will reset on the next build" >&2
fi
echo "$app"
