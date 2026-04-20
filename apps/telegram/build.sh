#!/usr/bin/env bash
# Telegram ships a dummy signing keystore + matching gradle.properties
# entries for reproducible builds, so the default keystore plumbing
# doesn't apply. The repo exposes three product flavors — two app
# bundles (bundleAfat*) and one universal APK (afat) — we only want
# the last one.
#
# The gradle project has several app modules (TMessagesProj_App, _App
# Standalone, _AppTests, _AppHuawei, _AppHockeyApp). They all produce
# an APK literally named "app.apk" in their own output dir, so a
# top-level assembleAfatRelease yields multiple same-named APKs that
# collide on upload. Scope to :TMessagesProj_App to get a single APK.
here="$(dirname "$0")"
exec "$here/../../common/gradle-release.sh" "$here/source" :TMessagesProj_App:assembleAfatRelease
