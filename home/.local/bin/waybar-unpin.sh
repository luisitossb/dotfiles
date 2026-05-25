#!/bin/bash
# Unpin an app from the taskbar.
# Called from pinned app button on-click-right.
# Usage: waybar-unpin.sh '<class>'
CLASS="$1"
PINS_FILE="$HOME/.config/waybar/pinned-apps.json"

pins=$(cat "$PINS_FILE" 2>/dev/null || echo "[]")
echo "$pins" | jq --arg c "$CLASS" '[.[] | select(.class != $c)]' > "$PINS_FILE"

notify-send "Taskbar" "Unpinned: $CLASS"
python3 ~/.local/bin/waybar-pinned-regen.py && bash "$HOME/.config/waybar/launch.sh"
