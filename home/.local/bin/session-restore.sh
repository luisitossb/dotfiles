#!/usr/bin/env bash
# Restore saved Hyprland session after reboot — runs from autostart
SESSION_FILE="$HOME/.local/share/hypr-session"
[[ -f "$SESSION_FILE" ]] || exit 0

# class name → launch command
declare -A CMD=(
    [kitty]="kitty"
    [discord]="discord"
    [zen]="zen-browser"
    [opera]="opera-gx"
    [org.qbittorrent.qBittorrent]="qbittorrent"
    [org.gnome.Nautilus]="nautilus"
    [thunar]="thunar"
    [obsidian]="obsidian"
    [dev.zed.Zed]="zed"
    [code]="code"
    [vscodium]="vscodium"
    [spotify]="spotify"
    [steam]="steam"
    [org.telegram.desktop]="telegram-desktop"
    [vlc]="vlc"
)

# Wait for Hyprland to be ready
sleep 3

while IFS=' ' read -r ws class; do
    cmd="${CMD[$class]:-}"
    if [[ -n "$cmd" ]]; then
        hyprctl dispatch exec "[workspace $ws silent] $cmd"
        sleep 0.4
    else
        echo "session-restore: no command for class '$class' (ws $ws)" >> /tmp/session-restore.log
    fi
done < "$SESSION_FILE"

rm "$SESSION_FILE"
notify-send "Session restored" "Apps reopened on their workspaces" 2>/dev/null
