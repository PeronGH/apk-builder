#!/usr/bin/env bash
# Telegram ships a dummy signing keystore + matching gradle.properties
# entries for reproducible builds, so the default keystore plumbing
# doesn't apply. The repo exposes three product flavors — two app
# bundles (bundleAfat*) and one universal APK (afat) — we only want
# the last one.
#
# Telegram pins ndkVersion 21.4.7075529, older than whatever the CI
# runner ships. sdkmanager installs it side-by-side under
# $ANDROID_HOME/ndk/21.4.7075529/ without disturbing any other NDK.
set -euo pipefail

here="$(dirname "$0")"

sdkmanager --install "ndk;21.4.7075529" >&2

exec "$here/../../common/gradle-release.sh" "$here/source" assembleAfatRelease
