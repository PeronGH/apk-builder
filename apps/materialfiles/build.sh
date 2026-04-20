#!/usr/bin/env bash
# Build MaterialFiles. Its signing.gradle loads credentials from
# signing.properties at the repo root — same key names as the default
# path, just a different file name — so we write that and hand off to
# the shared gradle-release utility.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
common="$app_dir/../../common"
src="$app_dir/source"

ks="$src/keyStore.jks"
"$common/keystore.sh" "$ks" >&2

cat >"$src/signing.properties" <<EOF
storeFile=$ks
storePassword=apkbuilder
keyAlias=apkbuilder
keyPassword=apkbuilder
EOF

exec "$common/gradle-release.sh" "$src"
