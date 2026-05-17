#!/usr/bin/env bash

_loadGameMode() {
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
}

if [ -f "$HOME/.config/quickshell/state/gamemode-enabled" ]; then
    _loadGameMode
    notify-send -u low -i joystick -a System "Gamemode activated" "Animations and blur are now disabled."
fi
