#!/bin/bash
# Set the Quickshell UI font.
# Usage: qs-set-font "Font Name"
# Called by the settings panel font chips.
# Kitty font is controlled independently via its own picker.

FONT="$1"
if [[ -z "$FONT" ]]; then
    echo "Usage: qs-set-font \"Font Name\"" >&2
    exit 1
fi

echo "$FONT" > "$HOME/.config/quickshell/settings/active-font"
qs ipc call theme-manager reload
