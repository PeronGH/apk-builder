#!/usr/bin/env bash
# v2rayNG's app module expects two native artefacts under V2rayNG/app/libs/
# at build time, neither of which is committed:
#   * libhev-socks5-tunnel .so per ABI, built here from the
#     hev-socks5-tunnel submodule via the upstream compile-hevtun.sh.
#   * libv2ray.aar, the Xray Go core, taken from the newest apps/libv2ray
#     release instead of 2dust's binary — we build our own so the core's
#     transport-security policy can be patched.
# compile-hevtun.sh calls $NDK_HOME/ndk-build; we reuse whichever NDK the
# runner image already ships (exposed as ANDROID_NDK_HOME) so we don't
# pay for another few-GB sdkmanager download on every build.
# Patches drop the ABI splits block so one universal APK is produced per
# flavor; we scope gradle to the playstore flavor since the fdroid flavor
# suffixes the applicationId with ".fdroid".
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/source"

export NDK_HOME="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:?no NDK available — set ANDROID_NDK_HOME}}"

(cd "$src" && bash compile-hevtun.sh) >&2
mkdir -p "$src/V2rayNG/app/libs"
cp -r "$src/libs/." "$src/V2rayNG/app/libs/"

tag="$(gh release list --limit 100 --json tagName \
    --jq 'map(.tagName | select(startswith("libv2ray-"))) | first')"
: "${tag:?no libv2ray release to pull the core from}"
gh release download "$tag" \
    --pattern libv2ray.aar --dir "$src/V2rayNG/app/libs" --clobber >&2

exec "$here/../../common/gradle-release.sh" "$src/V2rayNG" :app:assemblePlaystoreRelease
