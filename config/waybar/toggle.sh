#!/usr/bin/env bash

STATE="$HOME/.config/quickshell/state/waybar-disabled"
if [ -f "$STATE" ]; then
    rm "$STATE"
else
    touch "$STATE"
fi
$HOME/.config/waybar/launch.sh &
