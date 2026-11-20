#!/usr/bin/env bash
# Installs the apps after a fresh Arch installation. Run as your user, it uses sudo.
# Safe to run again: everything already installed is skipped.
# Lists (next to this scripts folder): packages.txt (official repos), aur.txt (AUR),
# one package per line, everything after # is ignored.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run as your user, not as root (makepkg and yay refuse root)." >&2
    exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"

# Package names of a list file, without comments and empty lines
list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' -e '/^$/d' "$1"
}

# 1. Official packages (also updates the system)
mapfile -t packages < <(list "$root/packages.txt")
sudo pacman -Syu --needed "${packages[@]}"

# 2. Manually built apps (scripts/man_builds/), yay among them
"$root/scripts/update_man_builds.sh"

# 3. AUR packages
mapfile -t aur < <(list "$root/aur.txt")
if [[ ${#aur[@]} -gt 0 ]]; then
    yay -S --needed "${aur[@]}"
fi

# 4. Services that pacman installs but does not enable
sudo systemctl enable --now NetworkManager.service bluetooth.service
