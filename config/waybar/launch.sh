#!/usr/bin/env bash

exec 200>/tmp/waybar-launch.lock
flock -n 200 || exit 0

killall waybar 2>/dev/null; pkill waybar 2>/dev/null
sleep 0.5

if [ ! -f "$HOME/.config/quickshell/state/waybar-disabled" ]; then
    HYPRLAND_SIGNATURE=$(hyprctl instances -j | jq -r '.[0].instance')
    HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_SIGNATURE" \
        waybar \
        -c ~/.config/waybar/themes/glass-center/config \
        -s ~/.config/waybar/themes/glass-center/default/style.css &
else
    echo ":: Waybar disabled"
fi

flock -u 200
exec 200>&-
