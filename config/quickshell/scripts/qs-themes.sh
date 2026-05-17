#!/usr/bin/env bash
# Color mode switcher — rofi picks light or dark, matugen regenerates palette

WALLPAPER=$(cat ~/.cache/qs-dotfiles/current_wallpaper 2>/dev/null)
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    notify-send -u normal -a System "Theme" "No current wallpaper found"
    exit 1
fi

selected=$(printf "dark\nlight" | rofi -dmenu -replace -config ~/.config/rofi/config-themes.rasi -i -no-show-icons -l 2 -width 20 -p "Color Mode")
[[ -z "$selected" ]] && exit 0

matugen image "$WALLPAPER" --source-color-index 0 -m "$selected"
qs ipc call theme-manager reload
nohup bash -c "$HOME/.config/waybar/launch.sh" >/dev/null 2>&1 &
nohup bash -c "$HOME/.config/nwg-dock-hyprland/launch.sh" >/dev/null 2>&1 &
swaync-client -rs
notify-send -u low -a System "Theme" "Switched to $selected mode"
