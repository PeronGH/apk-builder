#!/usr/bin/env bash
# Sign (or re-sign) APKs in-place with the CI keystore via uber-apk-signer.
# Env:
#   SIGNING_KEYSTORE_B64   base64-encoded JKS keystore, alias "release",
#                          store + key password "apkbuilder".
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: sign-apks.sh <apk> [<apk>...]" >&2
    exit 1
fi

: "${SIGNING_KEYSTORE_B64:?SIGNING_KEYSTORE_B64 not set}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
chmod 700 "$tmp"

ks="$tmp/keystore.jks"
base64 -d <<<"$SIGNING_KEYSTORE_B64" >"$ks"

uas_version="${UBER_APK_SIGNER_VERSION:-1.3.0}"
uas_jar="${UBER_APK_SIGNER_JAR:-$HOME/.cache/uber-apk-signer-$uas_version.jar}"
if [ ! -f "$uas_jar" ]; then
    mkdir -p "$(dirname "$uas_jar")"
    curl -fsSL \
        "https://github.com/patrickfav/uber-apk-signer/releases/download/v${uas_version}/uber-apk-signer-${uas_version}.jar" \
        -o "$uas_jar"
fi

java -jar "$uas_jar" \
    --apks "$@" \
    --ks "$ks" \
    --ksAlias release \
    --ksPass apkbuilder \
    --ksKeyPass apkbuilder \
    --allowResign \
    --overwrite
