# apk-builder

Builds third-party Android APKs from upstream source, applies patches, re-signs with our release key, publishes via GitHub releases.

## Layout

- `apps/<name>/source/` — upstream repo, shallow submodule
- `apps/<name>/build.sh` — per-app entry point (required, executable)
- `apps/<name>/patches/NN-*.patch` — numbered, applied from the submodule root with `patch -p1 --fuzz=3` before `build.sh` runs
- `apps/<name>/changed.sh` — optional change-detection override
- `common/*.sh` — shared build primitives (keystore, gradle-release, default-build, sign-apks)
- `builder/*.sh` — CI dispatchers
- `.github/workflows/{build,bump}.yml` — CI

## Submodules

Pass `--name <app>` so the local gitdir ends up at `.git/modules/<app>/`, not `.git/modules/apps/<app>/source/` (the default, derived from path):

```
git submodule add --name <app> --depth 1 -b <branch> <url> apps/<app>/source
```

Hand-edit `.gitmodules` afterward to add `shallow = true` — `git submodule add` won't write it.

## build.sh

Executable, `set -euo pipefail`. Print APK paths to **stdout**, everything else to **stderr** — `builder/build.sh` captures stdout as the APK list.

Delegate to a shared primitive:
- `common/default-build.sh <gradle-root> [props-filename]` — generates a throwaway keystore + matching properties file, then runs `assembleRelease`. Use for apps without their own signing config.
- `common/gradle-release.sh <gradle-root> [task]` — just gradle + find. Use for apps that ship their own signing (e.g. telegram).

Scope gradle narrowly when upstream emits multiple APKs we don't want — by module (`:TMessagesProj_App:assembleAfatRelease`), by flavor (`:app:assemblePlaystoreRelease`), or both. Output filenames within a release must be distinct (`gh release create` rejects duplicate asset names); this is why telegram scopes to one of the `:TMessagesProj_*` modules, which all emit `app.apk`.

## Patches

- `NN-<slug>.patch`, zero-padded — order is stable and applied ascending.
- One concern per patch.
- Paths are relative to the submodule root (`V2rayNG/app/...`, `TMessagesProj/...`).
- Fuzz up to 3 is tolerated.

## Signing

Two keystores, don't confuse them:

- **Build-time** (`common/keystore.sh`, alias `apkbuilder`, password `apkbuilder`) — throwaway, regenerated per build. Exists only so gradle will emit a release APK.
- **Release** (`common/sign-apks.sh`, alias `release`, password `apkbuilder`, loaded from the `SIGNING_KEYSTORE_B64` secret) — the real key, applied after build via `uber-apk-signer --allowResign --overwrite`.

Build-sign → release-resign is the expected flow for every app. Apps with upstream signing configs (telegram) skip the build-time keystore entirely; CI re-signs regardless.

## Commits

`<type>(<scope>): <subject>` — type ∈ {feat, fix, refactor, revert, chore, ci}; scope is the app name, or `build` for common infra. Explain *why* in the body; the diff already says *what*.

## Institutional memory

- **Don't pre-install NDKs.** Gradle auto-installs when `android.ndkVersion` is declared in the project. If a pre-gradle step needs `NDK_HOME` (e.g. `compile-hevtun.sh` for v2rayng), reuse `$ANDROID_NDK_HOME` from the runner image — don't burn build time on `sdkmanager --install` unless CI proves the shipped NDK is incompatible. Telegram had a speculative NDK install; it was reverted once CI showed gradle handled it.
- **Wait for CI evidence before defensive fixes** more generally — no workarounds ahead of a real failure.
- **Release tag = `<app>-<short-sha>` of the submodule HEAD.** `build.yml` deletes and recreates the tag on each run, so fixup commits overwrite the same tag.
- **`bump.yml` commits per-app** (`chore: bump <app>`) and passes the pre-bump SHA as `before` to `build.yml`, so only the bumped apps rebuild.
