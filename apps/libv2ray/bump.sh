#!/usr/bin/env bash
# Both submodules move: AndroidLibXrayLite is what we build, xray-core is
# the dependency we patch and swap in.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

git submodule update --remote "$here/source" "$here/xray-core"
