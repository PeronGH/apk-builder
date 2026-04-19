#!/usr/bin/env bash
# Build release APK(s); print resulting APK paths to stdout.
# The signature here is a throwaway to satisfy gradle's release signingConfig;
# the pipeline re-signs with the real key via uber-apk-signer.
set -euo pipefail

src="$(cd "$(dirname "$0")/source" && pwd)"

ks="$src/app/keyStore.jks"
if [ ! -f "$ks" ]; then
    keytool -genkeypair -noprompt \
        -keystore "$ks" \
        -alias apkbuilder \
        -keyalg RSA -keysize 2048 \
        -validity 3650 \
        -storepass apkbuilder -keypass apkbuilder \
        -dname "CN=apk-builder"
fi

cat >"$src/keystore.properties" <<EOF
storePassword=apkbuilder
keyPassword=apkbuilder
keyAlias=apkbuilder
storeFile=keyStore.jks
EOF

(cd "$src" && ./gradlew assembleRelease) >&2

find "$src/app/build/outputs/apk/release" -name '*.apk' -print
