#!/usr/bin/env bash
#    ___           __
#   / _ \___  ____/ /__
#  / // / _ \/ __/  '_/
# /____/\___/\__/_/\_\
#

DOCK_THEME="glass"

if [ ! -f "$HOME/.config/quickshell/state/dock-disabled" ]; then
    killall nwg-dock-hyprland
    sleep 0.5
    nwg-dock-hyprland -i 32 -w 5 -mb 10 -x -s themes/$DOCK_THEME/style.css -c "$HOME/.config/hypr/scripts/launcher.sh"
else
    killall nwg-dock-hyprland
    echo ":: Dock disabled"
fi
