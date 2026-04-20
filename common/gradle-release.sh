#!/usr/bin/env bash
# Run a gradle release task in the given directory and print paths to
# the resulting release APKs on stdout. Gradle output goes to stderr.
#
# usage: gradle-release.sh <gradle-root> [task]
#
# task defaults to "assembleRelease". Apps with product flavors may
# pass something narrower like "assembleAfatRelease". Debug APKs are
# filtered out of the output.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: gradle-release.sh <gradle-root> [task]" >&2
    exit 2
fi

root="$(cd "$1" && pwd)"
task="${2:-assembleRelease}"

(cd "$root" && ./gradlew "$task") >&2
find "$root" -path '*/build/outputs/apk/*.apk' ! -path '*/debug/*' -print
