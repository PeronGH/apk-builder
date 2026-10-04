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
# patches/00-xray-core-local-replace.patch. bump.sh keeps that submodule on
# the commit go.mod requires, so go.sum already covers the module graph and
# there is nothing here to resolve.
#
# gomobile wants an NDK; we reuse whichever one the runner image ships
# rather than pay for an sdkmanager download.
#
# Patches to xray-core's .proto files touch only the schema; the matching
# .pb.go is regenerated here so the patch never carries generated code,
# whose embedded descriptor bytes break on any upstream schema change.
# protoc-gen-go is built from xray-core's own module graph, so it matches
# the protobuf runtime the core links against.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/source"
core="$here/xray-core"

export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:?no NDK available — set ANDROID_NDK_HOME}}"

mapfile -t protos < <(git -C "$core" diff --name-only -- '*.proto')
if [ ${#protos[@]} -gt 0 ]; then
    sudo apt-get update -qq >&2
    sudo apt-get install -y -qq protobuf-compiler >&2
    gobin="$(mktemp -d)"
    (cd "$core" && GOBIN="$gobin" go install google.golang.org/protobuf/cmd/protoc-gen-go) >&2
    (cd "$core" && PATH="$gobin:$PATH" protoc -I . \
        --go_out=. --go_opt=paths=source_relative "${protos[@]}") >&2
fi

mkdir -p "$src/data" "$src/assets"
(cd "$src" && bash gen_assets.sh download) >&2
cp "$src"/data/*.dat "$src/assets/"

PATH="$(go env GOPATH)/bin:$PATH"
go install golang.org/x/mobile/cmd/gomobile@latest >&2
gomobile init >&2
(cd "$src" && gomobile bind -v -androidapi 24 -trimpath \
    -ldflags='-s -w -buildid= -checklinkname=0' ./) >&2

echo "$src/libv2ray.aar"
