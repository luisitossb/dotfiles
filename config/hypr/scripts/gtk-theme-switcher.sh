#!/usr/bin/env bash
# Watches GTK settings for dark/light preference changes and re-runs matugen

SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
SETTINGS_DIR="$HOME/.config/gtk-3.0"

if ! command -v inotifywait &>/dev/null; then
    echo "Error: inotify-tools not installed"
    exit 1
fi

apply_theme() {
    if [ ! -f "$SETTINGS_FILE" ]; then return 1; fi
    THEME_PREF=$(grep -E '^gtk-application-prefer-dark-theme=' "$SETTINGS_FILE" | awk -F'=' '{print $2}')
    if [[ "$THEME_PREF" == "1" || "$THEME_PREF" == "true" ]]; then
        MODE="dark"
    elif [[ "$THEME_PREF" == "0" || "$THEME_PREF" == "false" ]]; then
        MODE="light"
    else
        return 0
    fi

    WALLPAPER=$(cat ~/.cache/qs-dotfiles/current_wallpaper 2>/dev/null)
    [[ -z "$WALLPAPER" ]] && return 0

    matugen image "$WALLPAPER" --source-color-index 0 -m "$MODE"
    qs ipc call theme-manager reload
    nohup bash -c "$HOME/.config/waybar/launch.sh" >/dev/null 2>&1 &
    nohup bash -c "$HOME/.config/nwg-dock-hyprland/launch.sh" >/dev/null 2>&1 &
    $HOME/.config/hypr/scripts/gtk.sh &
    swaync-client -rs
}

inotifywait -m -q -e close_write,moved_to "$SETTINGS_DIR" | while read -r dir events filename; do
    if [[ "$filename" == "settings.ini" ]]; then
        apply_theme
    fi
done
