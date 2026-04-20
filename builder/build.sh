#!/usr/bin/env bash
# Dispatch build for an app. Prints resulting APK paths to stdout.
#
# usage: build.sh <app-dir>
#
# Patches under apps/<name>/patches/NN-*.patch are applied first. Then,
# if apps/<name>/build.sh exists, dispatches to it. Otherwise, runs the
# default: throwaway keystore + gradle assembleRelease. The pipeline
# re-signs the resulting APKs with the real key.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: build.sh <app-dir>" >&2
    exit 2
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
common="$here/../common"
app_dir="$(cd "$1" && pwd)"
src="$app_dir/source"

if [ -d "$app_dir/patches" ]; then
    for patch in "$app_dir/patches"/[0-9][0-9]-*.patch; do
        [ -f "$patch" ] || continue
        echo "applying $patch" >&2
        patch -p1 --forward --fuzz=3 -d "$src" <"$patch" >&2
    done
fi

if [ -x "$app_dir/build.sh" ]; then
    exec "$app_dir/build.sh"
fi

ks="$src/keyStore.jks"
"$common/keystore.sh" "$ks" >&2

# Two filenames because different gradle setups read one or the other
# (os-updater: keystore.properties, MaterialFiles: signing.properties).
# Same key/value shape, so we just write both.
for name in keystore.properties signing.properties; do
    cat >"$src/$name" <<EOF
storeFile=$ks
storePassword=apkbuilder
keyAlias=apkbuilder
keyPassword=apkbuilder
EOF
done

exec "$common/gradle-release.sh" "$src"
