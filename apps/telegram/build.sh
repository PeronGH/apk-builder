#!/usr/bin/env bash
# Telegram ships a dummy signing keystore + matching gradle.properties
# entries for reproducible builds, so the default keystore plumbing
# doesn't apply. The repo exposes three product flavors — two app
# bundles (bundleAfat*) and one universal APK (afat) — we only want
# the last one.
here="$(dirname "$0")"
exec "$here/../../common/gradle-release.sh" "$here/source" assembleAfatRelease
