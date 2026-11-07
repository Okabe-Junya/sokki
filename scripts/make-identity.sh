#!/bin/sh
# Creates a self-signed code signing identity in the login keychain.
#
# A stable identity keeps the app's designated requirement the same across
# rebuilds, so macOS keeps the privacy permissions you granted. Ad-hoc
# signatures change every build and lose them.
#
# Usage: make-identity.sh [name]   (default "Sokki Development")
set -eu

name=${1:-Sokki Development}
keychain="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning | grep -q "\"$name\""; then
  echo "identity \"$name\" already exists"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

openssl req -x509 -newkey rsa:2048 -keyout "$tmp/key.pem" -out "$tmp/cert.pem" \
  -days 3650 -nodes -subj "/CN=$name" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" \
  -addext "basicConstraints=critical,CA:FALSE" 2>/dev/null

# `security import` rejects the PKCS#12 defaults of OpenSSL 3 ("MAC verification failed").
openssl pkcs12 -export -out "$tmp/id.p12" -inkey "$tmp/key.pem" -in "$tmp/cert.pem" \
  -passout pass:x -name "$name" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
security import "$tmp/id.p12" -k "$keychain" -P x -T /usr/bin/codesign

# An imported self-signed certificate is untrusted, and codesign refuses untrusted identities.
security add-trusted-cert -r trustRoot -p codeSign -k "$keychain" "$tmp/cert.pem"

security find-identity -v -p codesigning | grep "\"$name\""
