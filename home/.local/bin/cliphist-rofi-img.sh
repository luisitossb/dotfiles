#!/bin/bash
CACHE="/tmp/cliphist-rofi-img"
mkdir -p "$CACHE"

# Clean cache entries older than 1 hour
find "$CACHE" -name "*.png" -mmin +60 -delete 2>/dev/null

case "$1" in
    d)
        cliphist list | while IFS= read -r line; do
            _rofi_entry "$line"
        done | rofi -dmenu -replace -p "Delete entry" \
            -config ~/.config/rofi/config-cliphist-img.rasi \
            | cliphist delete
        ;;
    *)
        cliphist list | while IFS= read -r line; do
            if printf '%s' "$line" | grep -q '\[\[ binary data.*png'; then
                id=$(printf '%s' "$line" | cut -f1)
                img="$CACHE/$id.png"
                if [ ! -f "$img" ]; then
                    printf '%s' "$line" | cliphist decode > "$img" 2>/dev/null
                fi
                printf '%s\0icon\x1f%s\n' "$line" "$img"
            else
                printf '%s\n' "$line"
            fi
        done | rofi -dmenu -replace -p "Clipboard" \
            -config ~/.config/rofi/config-cliphist-img.rasi \
            | cliphist decode | wl-copy
        ;;
esac
