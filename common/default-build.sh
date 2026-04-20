#!/usr/bin/env bash
# Shared default build: throwaway keystore, properties file, and gradle
# assembleRelease. Most apps only differ on the properties filename.
#
# usage: default-build.sh <gradle-root> [properties-filename]
#
# <gradle-root> is the directory containing gradlew (often <app>/source,
# sometimes a subdir like <app>/source/manager). The properties file is
# written there with storeFile, storePassword, keyAlias, keyPassword —
# the four keys every signingConfig we've seen reads. Defaults to
# "keystore.properties".
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: default-build.sh <gradle-root> [properties-filename]" >&2
    exit 2
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$1" && pwd)"
props="${2:-keystore.properties}"
ks="$root/keyStore.jks"

"$here/keystore.sh" "$ks" >&2

cat >"$root/$props" <<EOF
storeFile=$ks
storePassword=apkbuilder
keyAlias=apkbuilder
keyPassword=apkbuilder
EOF

exec "$here/gradle-release.sh" "$root"
