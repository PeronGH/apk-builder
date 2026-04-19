#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: sign-apk.sh <apk> [<apk>...]" >&2
    exit 1
fi

: "${SIGNING_KEY_PK8_B64:?SIGNING_KEY_PK8_B64 not set}"
: "${SIGNING_CERT_B64:?SIGNING_CERT_B64 not set}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
chmod 700 "$tmp"

base64 -d <<<"$SIGNING_KEY_PK8_B64" >"$tmp/key.pk8"
base64 -d <<<"$SIGNING_CERT_B64" >"$tmp/cert.x509.pem"

for apk in "$@"; do
    apksigner sign --key "$tmp/key.pk8" --cert "$tmp/cert.x509.pem" "$apk"
done
