#!/usr/bin/env bash
# v2rayNG's app module expects two native artefacts under V2rayNG/app/libs/
# at build time, neither of which is committed:
#   * libhev-socks5-tunnel .so per ABI, built here from the
#     hev-socks5-tunnel submodule via the upstream compile-hevtun.sh.
#   * libv2ray.aar, shipped as a binary release of 2dust/AndroidLibXrayLite
#     — we download the release matching the pinned submodule tag rather
#     than rebuild the Go core ourselves.
# compile-hevtun.sh calls $NDK_HOME/ndk-build, so we install the NDK that
# upstream pins (28.2.13676358) and point NDK_HOME at it.
# Patches drop the ABI splits block so one universal APK is produced per
# flavor; we scope gradle to the playstore flavor since the fdroid flavor
# suffixes the applicationId with ".fdroid".
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/source"
ndk_version="28.2.13676358"

sdkmanager --install "ndk;$ndk_version" >&2
export NDK_HOME="$ANDROID_HOME/ndk/$ndk_version"

(cd "$src" && bash compile-hevtun.sh) >&2
mkdir -p "$src/V2rayNG/app/libs"
cp -r "$src/libs/." "$src/V2rayNG/app/libs/"

xray_tag="$(git -C "$src/AndroidLibXrayLite" describe --tags --abbrev=0)"
curl -fsSL -o "$src/V2rayNG/app/libs/libv2ray.aar" \
    "https://github.com/2dust/AndroidLibXrayLite/releases/download/$xray_tag/libv2ray.aar"

exec "$here/../../common/gradle-release.sh" "$src/V2rayNG" :app:assemblePlaystoreRelease
