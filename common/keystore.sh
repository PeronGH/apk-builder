#!/usr/bin/env bash
# Create a throwaway RSA keystore at the given path if one is not there.
# Alias and both passwords are "apkbuilder". Callers write the matching
# properties file themselves since formats differ between gradle plugins.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: keystore.sh <jks-path>" >&2
    exit 2
fi

ks="$1"
[ -f "$ks" ] && exit 0

keytool -genkeypair -noprompt \
    -keystore "$ks" \
    -alias apkbuilder \
    -keyalg RSA -keysize 2048 \
    -validity 3650 \
    -storepass apkbuilder -keypass apkbuilder \
    -dname "CN=apk-builder"
