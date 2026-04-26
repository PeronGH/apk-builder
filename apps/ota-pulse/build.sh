#!/usr/bin/env bash
# OTA-Pulse hardcodes its signingConfig: alias "release", reads
# STORE_PASSWORD/KEY_PASSWORD (uppercase) from keystore.properties,
# and resolves storeFile to keystore.jks at the project root. None
# of those match common/default-build.sh's defaults, so generate the
# build-time keystore inline and call gradle-release.sh directly.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/source"
ks="$src/keystore.jks"

if [ ! -f "$ks" ]; then
    keytool -genkeypair -noprompt \
        -keystore "$ks" \
        -alias release \
        -keyalg RSA -keysize 2048 \
        -validity 3650 \
        -storepass apkbuilder -keypass apkbuilder \
        -dname "CN=apk-builder" >&2
fi

cat >"$src/keystore.properties" <<EOF
STORE_PASSWORD=apkbuilder
KEY_PASSWORD=apkbuilder
EOF

exec "$here/../../common/gradle-release.sh" "$src"
