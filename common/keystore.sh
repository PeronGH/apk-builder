#!/usr/bin/env bash
# Create a throwaway RSA keystore at the given path if one is not there.
# Both passwords are "apkbuilder"; the alias defaults to "apkbuilder"
# but can be overridden for upstreams that hardcode a different one.
# Callers write the matching properties file themselves since formats
# differ between gradle plugins.
#
# usage: keystore.sh <jks-path> [alias]
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: keystore.sh <jks-path> [alias]" >&2
    exit 2
fi

ks="$1"
alias="${2:-apkbuilder}"
[ -f "$ks" ] && exit 0

keytool -genkeypair -noprompt \
    -keystore "$ks" \
    -alias "$alias" \
    -keyalg RSA -keysize 2048 \
    -validity 3650 \
    -storepass apkbuilder -keypass apkbuilder \
    -dname "CN=apk-builder"
