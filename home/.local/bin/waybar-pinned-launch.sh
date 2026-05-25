#!/bin/bash
# Focus the app if running, otherwise launch it.
# Usage: waybar-pinned-launch.sh '<class>' <exec command>
CLASS="$1"
shift
EXEC="$@"

lower="${CLASS,,}"

IS_RUNNING=$(hyprctl clients -j 2>/dev/null | \
    jq --arg c "$lower" 'any(.[]; (.class | ascii_downcase) == $c)' 2>/dev/null)

if [ "$IS_RUNNING" = "true" ]; then
    hyprctl dispatch focuswindow "class:${CLASS}"
else
    $EXEC &
fi
