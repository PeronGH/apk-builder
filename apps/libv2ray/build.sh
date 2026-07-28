#!/usr/bin/env bash
# libv2ray.aar — the Xray Go core, packaged for Android by gomobile.
#
# 2dust publish this as a release binary, but the core is where the
# transport-security policy lives, so we build it from source we can patch
# (see patches/xray-core/). apps/v2rayng consumes the release this produces
# rather than 2dust's, pinned by apps/v2rayng/libv2ray.tag.
#
# AndroidLibXrayLite pulls xray-core as a plain module dependency; the
# xray-core submodule is our patchable checkout of it, swapped in by
# patches/00-xray-core-local-replace.patch.
#
# gomobile wants an NDK; we reuse whichever one the runner image ships
# rather than pay for an sdkmanager download.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/source"

export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:?no NDK available — set ANDROID_NDK_HOME}}"

mkdir -p "$src/data" "$src/assets"
(cd "$src" && bash gen_assets.sh download) >&2
cp "$src"/data/*.dat "$src/assets/"

PATH="$(go env GOPATH)/bin:$PATH"
go install golang.org/x/mobile/cmd/gomobile@latest >&2
gomobile init >&2
(cd "$src" && go mod tidy && gomobile bind -v -androidapi 24 -trimpath \
    -ldflags='-s -w -buildid= -checklinkname=0' ./) >&2

echo "$src/libv2ray.aar"
