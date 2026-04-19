#!/usr/bin/env bash
# Dispatch build for an app. Prints resulting APK paths to stdout.
#
# usage: build.sh <app-dir>
#
# If apps/<name>/build.sh exists, defers to it. Otherwise, runs the
# default gradle build: generate a throwaway keystore (to satisfy any
# hard-required release signingConfig), run ./gradlew assembleRelease,
# and list release APKs. The pipeline re-signs with the real key.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: build.sh <app-dir>" >&2
    exit 2
fi

app_dir="$(cd "$1" && pwd)"

if [ -x "$app_dir/build.sh" ]; then
    exec "$app_dir/build.sh"
fi

src="$app_dir/source"
ks="$src/keyStore.jks"

if [ ! -f "$ks" ]; then
    keytool -genkeypair -noprompt \
        -keystore "$ks" \
        -alias apkbuilder \
        -keyalg RSA -keysize 2048 \
        -validity 3650 \
        -storepass apkbuilder -keypass apkbuilder \
        -dname "CN=apk-builder" >&2
fi

cat >"$src/keystore.properties" <<EOF
storePassword=apkbuilder
keyPassword=apkbuilder
keyAlias=apkbuilder
storeFile=$ks
EOF

(cd "$src" && ./gradlew assembleRelease) >&2

find "$src" -path '*/build/outputs/apk/release/*.apk' -print
