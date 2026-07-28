#!/usr/bin/env bash
# Dispatch build for an app. Prints resulting APK paths to stdout.
#
# usage: build.sh <app-dir>
#
# Patches under apps/<name>/patches/NN-*.patch are applied to
# apps/<name>/source first, then apps/<name>/build.sh runs. Every app
# declares its own build.sh — typical ones are a 3-line wrapper around
# common/default-build.sh.
#
# An app with more than one submodule puts the extra ones' patches in
# apps/<name>/patches/<submodule>/NN-*.patch, applied to apps/<name>/<submodule>.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: build.sh <app-dir>" >&2
    exit 2
fi

app_dir="$(cd "$1" && pwd)"
src="$app_dir/source"

apply_patches() {
    local dir="$1" target="$2" patch
    for patch in "$dir"/[0-9][0-9]-*.patch; do
        [ -f "$patch" ] || continue
        echo "applying $patch" >&2
        patch -p1 --forward --fuzz=3 -d "$target" <"$patch" >&2
    done
}

apply_patches "$app_dir/patches" "$src"

for dir in "$app_dir/patches"/*/; do
    [ -d "$dir" ] || continue
    sub="$(basename "$dir")"
    if [ ! -d "$app_dir/$sub" ]; then
        echo "patches/$sub/ has no matching submodule at $app_dir/$sub" >&2
        exit 1
    fi
    apply_patches "$dir" "$app_dir/$sub"
done

if [ ! -x "$app_dir/build.sh" ]; then
    echo "$app_dir/build.sh missing or not executable" >&2
    exit 1
fi

exec "$app_dir/build.sh"
