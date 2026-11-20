#!/usr/bin/env bash
# Builds and installs (or updates) every manually built app: runs each script in
# man_builds/. Stops at the first failing build.
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)/man_builds"

for build in "$dir"/*.sh; do
    echo "==> $(basename "$build" .sh)"
    bash "$build"
done
