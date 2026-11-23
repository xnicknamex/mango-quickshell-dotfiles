#!/usr/bin/env bash
# Downloads and installs Heroic Games Launcher from GitHub Releases.
# Install and update: packages are cached in ~/.cache/man_builds/heroic (the
# last three versions are kept); skipped if the latest version is installed.
# The download is checked against the SHA-256 that GitHub lists for the file.
set -euo pipefail

src="${XDG_CACHE_HOME:-$HOME/.cache}/man_builds/heroic"
api="https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest"

case "$(uname -m)" in
    x86_64)  arch="x64" ;;
    aarch64) arch="aarch64" ;;
    *) echo "Unsupported architecture" >&2; exit 1 ;;
esac

release="$(curl -fsSL "$api")"
tag="$(jq -r .tag_name <<<"$release")"
latest="${tag#v}"

installed="$(pacman -Q heroic 2>/dev/null | awk '{print $2}' || true)"
if [[ "$installed" == "$latest"-* ]]; then
    echo "Heroic $latest is already installed"
    exit 0
fi

name="Heroic-$latest-linux-$arch.pacman"
file="$src/$name"
asset() {
    jq -r --arg n "$name" --arg f "$1" '.assets[] | select(.name == $n) | .[$f] // empty' <<<"$release"
}
url="$(asset browser_download_url)"
sha="$(asset digest)"
sha="${sha#sha256:}"
if [[ -z "$url" || -z "$sha" ]]; then
    echo "$name or its checksum is missing in release $tag" >&2
    exit 1
fi

mkdir -p "$src"
if [[ ! -f "$file" ]]; then
    curl -fL --retry 3 -o "$file.part" "$url"
    mv "$file.part" "$file"
fi

# Also checks a cached file; a bad one is deleted so the next run downloads it again
if ! sha256sum -c --quiet <<<"$sha  $file"; then
    echo "Checksum mismatch, deleted $file" >&2
    rm -f "$file"
    exit 1
fi

# Both are stale dependencies of the package (Electron does not need them) and do not exist in Arch
sudo pacman -U --assume-installed http-parser --assume-installed libappindicator-gtk3 "$file"

# Keep the last three versions, delete older ones
ls -1v "$src"/Heroic-*-linux-"$arch".pacman | head -n -3 | xargs -r rm --
