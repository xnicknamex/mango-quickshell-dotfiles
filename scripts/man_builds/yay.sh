#!/usr/bin/env bash
# Builds and installs yay (AUR helper) from the AUR.
# Install and update: the source stays in ~/.cache/man_builds and is pulled again;
# the build is skipped when the installed version is already the newest.
set -euo pipefail

src="${XDG_CACHE_HOME:-$HOME/.cache}/man_builds/yay"

if [[ -d "$src/.git" ]]; then
    git -C "$src" pull --ff-only
else
    git clone https://aur.archlinux.org/yay.git "$src"
fi

latest="$(awk -F' = ' '$1 ~ /pkgver/ {v=$2} $1 ~ /pkgrel/ {r=$2} END {print v "-" r}' "$src/.SRCINFO")"
if [[ "$(pacman -Q yay 2>/dev/null | cut -d' ' -f2)" == "$latest" ]]; then
    echo "yay $latest is already installed"
    exit 0
fi

(cd "$src" && makepkg -si --force)
