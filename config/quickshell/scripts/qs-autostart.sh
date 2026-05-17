#!/usr/bin/env bash
# qs-autostart.sh — start Quickshell daemon + overview

CACHE_FILE="$HOME/.cache/qs-dotfiles/current_wallpaper"
QS_WALLPAPER="$HOME/.config/quickshell/scripts/qs-wallpaper.sh"

# Restore last wallpaper (runs in background so qs can start sooner)
if [[ -f "$CACHE_FILE" && -s "$CACHE_FILE" ]]; then
    bash "$QS_WALLPAPER" "$(cat "$CACHE_FILE")" &
fi

# Kill any existing qs instances and restart cleanly
killall qs 2>/dev/null
sleep 0.5

# Start main qs daemon
qs &
sleep 0.5

# Start Quickshell workspace overview (Super+Tab)
qs -p "$HOME/.config/quickshell/overview" &
