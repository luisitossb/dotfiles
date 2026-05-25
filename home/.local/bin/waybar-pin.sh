#!/bin/bash
# Pin a running app to the taskbar.
# Called from wlr/taskbar on-click-right.
PINS_FILE="$HOME/.config/waybar/pinned-apps.json"

pins=$(cat "$PINS_FILE" 2>/dev/null || echo "[]")

# Try to use the active window as the default suggestion
ACTIVE_CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')

# Build list of running apps not already pinned
mapfile -t entries < <(hyprctl clients -j 2>/dev/null | \
    jq -r '[.[]] | unique_by(.class) | .[] | .class + "\t" + .title' 2>/dev/null)

menu_lines=()
for entry in "${entries[@]}"; do
    cls=$(echo "$entry" | cut -f1)
    title=$(echo "$entry" | cut -f2-)
    # Skip already pinned
    if echo "$pins" | jq -e --arg c "$cls" '.[] | select(.class == $c)' > /dev/null 2>&1; then
        continue
    fi
    if [ "$cls" = "$ACTIVE_CLASS" ]; then
        menu_lines=("$cls — $title (active)" "${menu_lines[@]}")
    else
        menu_lines+=("$cls — $title")
    fi
done

if [ ${#menu_lines[@]} -eq 0 ]; then
    notify-send "Taskbar" "All running apps are already pinned"
    exit 0
fi

selected=$(printf '%s\n' "${menu_lines[@]}" | rofi -dmenu -p "Pin to taskbar:" -theme-str 'window {width: 420px;}')
[ -z "$selected" ] && exit 0

CLASS=$(echo "$selected" | awk '{print $1}')

# Pick an icon based on class name
case "${CLASS,,}" in
    *zen*)                      ICON="󰈹" ;;
    *firefox*)                  ICON="󰈹" ;;
    *chrome*|*chromium*)        ICON="󰊯" ;;
    *discord*)                  ICON="󰙯" ;;
    *kitty*|*alacritty*|*foot*) ICON="󰄛" ;;
    *nautilus*|*thunar*)        ICON="󰉋" ;;
    *spotify*)                  ICON="󰓇" ;;
    *steam*)                    ICON="󰓓" ;;
    *code*|*vscode*|*zed*)      ICON="󰨞" ;;
    *obsidian*)                 ICON="󱓧" ;;
    *telegram*)                 ICON="󰨝" ;;
    *vlc*)                      ICON="󰕼" ;;
    *qbittorrent*)              ICON="󰇚" ;;
    *)                          ICON="󰣆" ;;
esac

NAME="$CLASS"

echo "$pins" | jq \
    --arg c "$CLASS" --arg e "$CLASS" --arg i "$ICON" --arg n "$NAME" \
    '. + [{"class": $c, "exec": $e, "icon": $i, "name": $n}]' > "$PINS_FILE"

notify-send "Taskbar" "Pinned: $CLASS"
python3 ~/.local/bin/waybar-pinned-regen.py && bash "$HOME/.config/waybar/launch.sh"
