#!/usr/bin/env bash
# Run ./gradlew assembleRelease in the given directory and print paths to
# the resulting release APKs on stdout. Gradle output goes to stderr.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: gradle-release.sh <gradle-root>" >&2
    exit 2
fi

root="$(cd "$1" && pwd)"
(cd "$root" && ./gradlew assembleRelease) >&2
find "$root" -path '*/build/outputs/apk/release/*.apk' -print
