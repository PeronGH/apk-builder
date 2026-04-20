#!/usr/bin/env bash
# Build the KernelSU-Next manager APK (arm64-v8a only).
#
# KSN's manager shells out at runtime to an embedded ksud binary (Rust,
# packaged as libksud.so in jniLibs). This script cross-compiles ksud for
# aarch64-linux-android via cross, drops it into the manager's jniLibs,
# then runs the gradle build. LKM kernel modules and ksuinit are not
# built — the resulting manager works on kernels with KernelSU patched
# in, but cannot install LKM-mode drivers.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
common="$app_dir/../../common"
src="$app_dir/source"

: "${ANDROID_NDK_ROOT:?ANDROID_NDK_ROOT not set}"

rustup target add aarch64-linux-android >&2
if ! command -v cross >/dev/null 2>&1; then
    cargo install cross --git https://github.com/cross-rs/cross --rev 66845c1 >&2
fi

sysroot="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_linux_android="--sysroot=$sysroot -I$sysroot/usr/include/aarch64-linux-android -I$sysroot/usr/include"

(cd "$src" && cross build \
    --target aarch64-linux-android \
    --release \
    --manifest-path ./userspace/ksud/Cargo.toml) >&2

jnilibs="$src/manager/app/src/main/jniLibs/arm64-v8a"
mkdir -p "$jnilibs"
cp -f "$src/userspace/ksud/target/aarch64-linux-android/release/ksud" "$jnilibs/libksud.so"

"$common/keystore.sh" "$src/manager/key.jks" >&2

cat >>"$src/manager/gradle.properties" <<'EOF'
KEYSTORE_FILE=key.jks
KEYSTORE_PASSWORD=apkbuilder
KEY_ALIAS=apkbuilder
KEY_PASSWORD=apkbuilder
EOF

exec "$common/gradle-release.sh" "$src/manager"
