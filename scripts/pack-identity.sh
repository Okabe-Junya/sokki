#!/bin/sh
# Packs a Developer ID Application certificate and its private key into a
# PKCS#12 with Apple's intermediate, imports it into the login keychain, and
# prints the commands that store it as repository secrets for the release workflow.
#
# Usage: pack-identity.sh <private-key.pem> <developerID_application.cer>
#   The key is the one the certificate signing request was made with
#   (`openssl req -new -newkey rsa:2048 -nodes -keyout key.pem -out request.csr`).
set -eu

key=$1
cer=$2
out=$(mktemp -d)
password=$(openssl rand -base64 32)

curl -fsSL https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer -o "$out/intermediate.cer"
openssl x509 -inform der -in "$cer" -out "$out/leaf.pem"
openssl x509 -inform der -in "$out/intermediate.cer" -out "$out/intermediate.pem"
name=$(openssl x509 -in "$out/leaf.pem" -noout -subject -nameopt multiline | sed -n 's/^ *commonName *= *//p')

# `security import` rejects the PKCS#12 defaults of OpenSSL 3 ("MAC verification failed").
openssl pkcs12 -export -out "$out/identity.p12" -inkey "$key" -in "$out/leaf.pem" \
  -certfile "$out/intermediate.pem" -name "$name" -passout "pass:$password" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
rm -f "$out/leaf.pem" "$out/intermediate.pem" "$out/intermediate.cer"

security import "$out/identity.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
  -P "$password" -T /usr/bin/codesign
security find-identity -v -p codesigning | grep "\"$name\""

base64 -i "$out/identity.p12" -o "$out/identity.p12.base64"
printf '%s' "$password" > "$out/identity.password"
rm -f "$out/identity.p12"

cat <<EOF
Imported "$name" into the login keychain. Store it as repository secrets, then delete the directory:

  gh secret set SOKKI_SIGNING_P12_BASE64 --repo Okabe-Junya/sokki < "$out/identity.p12.base64"
  gh secret set SOKKI_SIGNING_P12_PASSWORD --repo Okabe-Junya/sokki < "$out/identity.password"
  rm -rf "$out"
EOF
