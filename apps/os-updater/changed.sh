#!/usr/bin/env bash
# Exit 0 if the app should be (re)built, 1 otherwise.
# Input: BEFORE_SHA env var (commit to compare against, optional).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(git -C "$here" rev-parse --show-toplevel)"
rel="${here#"$repo_root"/}"

before="${BEFORE_SHA:-}"
if [ -z "$before" ] || ! git -C "$repo_root" rev-parse --verify --quiet "$before^{commit}" >/dev/null; then
    exit 0
fi

if git -C "$repo_root" diff --quiet "$before" HEAD -- "$rel"; then
    exit 1
fi
