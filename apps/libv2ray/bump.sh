#!/usr/bin/env bash
# AndroidLibXrayLite moves to its branch tip; xray-core then follows whatever
# commit that tip's go.mod requires, rather than its own branch tip. Keeping
# the two in step is what lets build.sh skip dependency resolution entirely:
# the checked-out tree is the module go.sum already describes.
#
# go.mod carries a 12-char pseudo-version prefix and git can only fetch full
# object names, so the API expands it.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
core="$here/xray-core"

git submodule update --remote "$here/source"

pinned="$(awk '$1 == "github.com/xtls/xray-core" { n = split($2, part, "-"); print part[n] }' "$here/source/go.mod")"
if [ -z "$pinned" ]; then
    echo "no github.com/xtls/xray-core requirement in $here/source/go.mod" >&2
    exit 1
fi

slug="$(git -C "$core" remote get-url origin)"
slug="${slug#*github.com/}"
slug="${slug%.git}"

full="$(gh api "repos/$slug/commits/$pinned" --jq .sha)"
git -C "$core" fetch --depth 1 origin "$full"
git -C "$core" checkout --detach "$full"
