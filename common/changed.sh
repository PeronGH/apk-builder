#!/usr/bin/env bash
# Dispatch change detection for an app.
#
# usage: changed.sh <app-dir>
# env:   BEFORE_SHA  baseline commit to diff against (optional)
# exit:  0 if the app should be rebuilt, 1 otherwise
#
# If apps/<name>/changed.sh exists, defers to it. Otherwise, the default
# rule is "any file under <app-dir> changed between BEFORE_SHA and HEAD".
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: changed.sh <app-dir>" >&2
    exit 2
fi

app_dir="$(cd "$1" && pwd)"

if [ -x "$app_dir/changed.sh" ]; then
    exec "$app_dir/changed.sh"
fi

repo_root="$(git -C "$app_dir" rev-parse --show-toplevel)"
rel="${app_dir#"$repo_root"/}"

before="${BEFORE_SHA:-}"
if [ -z "$before" ] || ! git -C "$repo_root" rev-parse --verify --quiet "$before^{commit}" >/dev/null; then
    exit 0
fi

if git -C "$repo_root" diff --quiet "$before" HEAD -- "$rel"; then
    exit 1
fi
