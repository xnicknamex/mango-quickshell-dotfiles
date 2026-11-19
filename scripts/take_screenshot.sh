#!/usr/bin/env bash

# A failing grim must fail the whole pipeline, not just the last command
set -o pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

mode="${1:-full}"
if [[ "$mode" = "region" ]]; then
    # Abort if the selection is cancelled (Esc), otherwise an empty file is written
    region="$(slurp)" || exit 1
    grim -g "$region" - | tee "$file" | wl-copy --type image/png
else
    grim - | tee "$file" | wl-copy --type image/png
fi

if [[ $? -eq 0 ]]; then
    notify-send --app-name="screenshot" --icon="$file" --expire-time=1000 "Screenshot saved"
else
    rm -f "$file"
    notify-send --app-name="screenshot" --expire-time=1000 "Screenshot failed"
fi
