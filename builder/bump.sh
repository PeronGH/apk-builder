#!/usr/bin/env bash
# Dispatch submodule bumping for an app.
#
# usage: bump.sh <app-dir>
#
# If apps/<name>/bump.sh exists, defers to it. Otherwise the default is to
# move apps/<name>/source to its tracked branch tip. An app with more than
# one submodule declares its own bump.sh — bump.yml stays generic.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: bump.sh <app-dir>" >&2
    exit 2
fi

app_dir="$(cd "$1" && pwd)"

if [ -x "$app_dir/bump.sh" ]; then
    exec "$app_dir/bump.sh"
fi

git submodule update --remote "$app_dir/source"
