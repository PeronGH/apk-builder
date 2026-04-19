#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: build-app.sh <app-dir>" >&2
    exit 1
fi

app_dir="$1"

(cd "$app_dir" && ./gradlew --no-daemon assembleRelease)

find "$app_dir" -path '*/build/outputs/apk/release/*.apk' -print
