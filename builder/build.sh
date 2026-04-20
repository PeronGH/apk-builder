#!/usr/bin/env bash
# Dispatch build for an app. Prints resulting APK paths to stdout.
#
# usage: build.sh <app-dir>
#
# Patches under apps/<name>/patches/NN-*.patch are applied first, then
# apps/<name>/build.sh runs. Every app declares its own build.sh —
# typical ones are a 3-line wrapper around common/default-build.sh.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: build.sh <app-dir>" >&2
    exit 2
fi

app_dir="$(cd "$1" && pwd)"
src="$app_dir/source"

if [ -d "$app_dir/patches" ]; then
    for patch in "$app_dir/patches"/[0-9][0-9]-*.patch; do
        [ -f "$patch" ] || continue
        echo "applying $patch" >&2
        patch -p1 --forward --fuzz=3 -d "$src" <"$patch" >&2
    done
fi

if [ ! -x "$app_dir/build.sh" ]; then
    echo "$app_dir/build.sh missing or not executable" >&2
    exit 1
fi

exec "$app_dir/build.sh"
