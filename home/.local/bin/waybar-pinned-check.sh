#!/bin/bash
# Check if a pinned app is running/focused and output Waybar JSON.
# Usage: waybar-pinned-check.sh '<class>' '<icon>' '<name>'
CLASS="$1"
ICON="$2"
NAME="$3"

lower="${CLASS,,}"

IS_RUNNING=$(hyprctl clients -j 2>/dev/null | \
    jq --arg c "$lower" 'any(.[]; (.class | ascii_downcase) == $c)' 2>/dev/null)

if [ "$IS_RUNNING" = "true" ]; then
    ACTIVE=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // "" | ascii_downcase' 2>/dev/null)
    if [ "$ACTIVE" = "$lower" ]; then
        printf '{"text":"%s","class":"pin-app pin-running pin-active","tooltip":"%s"}\n' "$ICON" "$NAME"
    else
        printf '{"text":"%s","class":"pin-app pin-running","tooltip":"%s"}\n' "$ICON" "$NAME"
    fi
else
    printf '{"text":"%s","class":"pin-app pin-idle","tooltip":"%s (not running)"}\n' "$ICON" "$NAME"
fi
