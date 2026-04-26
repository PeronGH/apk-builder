#!/usr/bin/env bash
# OTA-Pulse hardcodes its signingConfig: alias "release", reads
# STORE_PASSWORD/KEY_PASSWORD (uppercase) from keystore.properties,
# and resolves storeFile to keystore.jks at the project root. The
# property shape doesn't match common/default-build.sh, so generate
# the keystore via common/keystore.sh (with an "release" alias
# override) and write our own properties file before handing off.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/source"

"$here/../../common/keystore.sh" "$src/keystore.jks" release >&2

cat >"$src/keystore.properties" <<EOF
STORE_PASSWORD=apkbuilder
KEY_PASSWORD=apkbuilder
EOF

exec "$here/../../common/gradle-release.sh" "$src"
