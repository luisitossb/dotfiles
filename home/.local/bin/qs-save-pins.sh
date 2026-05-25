#!/bin/bash
# Usage: qs-save-pins.sh '<json-string>'
printf '%s\n' "$1" > ~/.config/waybar/pinned-apps.json
