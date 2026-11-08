#!/bin/sh
# Imports the release signing identity into a temporary keychain on a CI runner.
#
# Usage: import-identity.sh [name]   (default "Sokki Development")
# Environment:
#   SOKKI_SIGNING_P12_BASE64    base64 PKCS#12 from scripts/export-identity.sh
#   SOKKI_SIGNING_P12_PASSWORD  its password
set -eu

if [ -z "${SOKKI_SIGNING_P12_BASE64:-}" ] || [ -z "${SOKKI_SIGNING_P12_PASSWORD:-}" ]; then
  echo "::error::Secrets SOKKI_SIGNING_P12_BASE64 and SOKKI_SIGNING_P12_PASSWORD are not set. Refusing to ship an ad-hoc signed app: it would reset every user's privacy permissions on update. Create them with scripts/export-identity.sh." >&2
  exit 1
fi

name=${1:-Sokki Development}
dir=$(mktemp -d "${RUNNER_TEMP:-/tmp}/signing.XXXXXX")
keychain="$dir/signing.keychain-db"
keychain_password=$(openssl rand -base64 32)

printf '%s' "$SOKKI_SIGNING_P12_BASE64" | base64 -d > "$dir/id.p12"

security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$dir/id.p12" -k "$keychain" -P "$SOKKI_SIGNING_P12_PASSWORD" -T /usr/bin/codesign
rm -f "$dir/id.p12"
security set-key-partition-list -S apple-tool:,apple: -s -k "$keychain_password" "$keychain" > /dev/null
security list-keychains -d user -s "$keychain" "$HOME/Library/Keychains/login.keychain-db"

# Not `-v`: a self-signed identity is untrusted, which codesign accepts and
# which keeps the designated requirement (`certificate leaf = H"..."`) stable.
security find-identity -p codesigning "$keychain" | grep "\"$name\""
