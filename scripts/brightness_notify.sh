#!/bin/sh

# Brightness popup (sync tag = only one at a time, value = progress bar).
# Not possible natively with Quickshell at the moment: it has no backlight API.

b=$(brightnessctl g)
m=$(brightnessctl m)
p=$(( b * 100 / m ))

notify-send -t 1000 -a 'br' \
  -h string:x-canonical-private-synchronous:brightness \
  -h int:value:$p \
  "Brightness: ${p}%"
