#!/bin/sh
# Exports the signing identity from the login keychain so the release workflow
# can sign with it, and prints the commands that store it as repository secrets.
#
# Usage: export-identity.sh [name]   (default "Sokki Development")
set -eu

name=${1:-Sokki Development}
keychain="$HOME/Library/Keychains/login.keychain-db"

# `security export` cannot pick one identity; it exports every identity in the keychain.
count=$(security find-identity "$keychain" | sed -n 's/^ *\([0-9][0-9]*\) identities found$/\1/p' | head -n 1)
if [ "$count" != 1 ] || ! security find-identity "$keychain" | grep -q "\"$name\""; then
  echo "error: the login keychain must hold exactly one identity, \"$name\" (found ${count:-0})" >&2
  exit 1
fi

out=$(mktemp -d)
password=$(openssl rand -base64 32)

security export -k "$keychain" -t identities -f pkcs12 -P "$password" -o "$out/identity.p12"
base64 -i "$out/identity.p12" -o "$out/identity.p12.base64"
printf '%s' "$password" > "$out/identity.password"
rm -f "$out/identity.p12"

cat <<EOF
Exported "$name" to $out. Store it as repository secrets, then delete the directory:

  gh secret set SOKKI_SIGNING_P12_BASE64 --repo Okabe-Junya/sokki < "$out/identity.p12.base64"
  gh secret set SOKKI_SIGNING_P12_PASSWORD --repo Okabe-Junya/sokki < "$out/identity.password"
  rm -rf "$out"
EOF
