#!/usr/bin/env bash
# Builds and installs uki-fallback (https://github.com/xnicknamex/uki-fallback) as a
# pacman package. Install and update: the source stays in ~/.cache/man_builds and is
# pulled again; pacman skips the install when the version (from git) is unchanged.
set -euo pipefail

src="${XDG_CACHE_HOME:-$HOME/.cache}/man_builds/uki-fallback"

if [[ -d "$src/.git" ]]; then
    git -C "$src" pull --ff-only
else
    git clone https://github.com/xnicknamex/uki-fallback.git "$src"
fi

(cd "$src" && makepkg -si --force --needed)
