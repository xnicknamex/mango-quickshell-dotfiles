#!/usr/bin/env bash
# Builds and installs spotify-adblock (https://github.com/abba23/spotify-adblock).
# Install and update: the source stays in ~/.cache/man_builds and is pulled again.
set -euo pipefail

src="${XDG_CACHE_HOME:-$HOME/.cache}/man_builds/spotify-adblock"

if [[ -d "$src/.git" ]]; then
    git -C "$src" pull --ff-only
else
    git clone https://github.com/abba23/spotify-adblock.git "$src"
fi

make -C "$src"
sudo make -C "$src" install
