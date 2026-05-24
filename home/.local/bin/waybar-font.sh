#!/bin/bash
# Set font for Waybar + Quickshell.
# Usage: waybar-font.sh [index]   — direct index (0/1/2)
#        waybar-font.sh            — cycle to next

FONTS=(
    "Press Start 2P|9"
    "Orbitron|9"
    "Monocraft|9"
    "Audiowide|10"
    "Oxanium|11"
    "VT323|14"
    "Rajdhani|11"
    "Exo 2|11"
)

STATE_FILE="$HOME/.config/waybar/active-font"
CSS_FILE="$HOME/.config/waybar/themes/glass-center/default/pixel-font.css"

if [[ -n "$1" ]]; then
    NEXT=$1
else
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
    NEXT=$(( (CURRENT + 1) % ${#FONTS[@]} ))
fi

echo "$NEXT" > "$STATE_FILE"

ENTRY="${FONTS[$NEXT]}"
FONT_NAME="${ENTRY%|*}"
FONT_SIZE="${ENTRY#*|}"

# Update Waybar CSS
cat > "$CSS_FILE" << EOF
#clock,
#pulseaudio,
#battery,
#custom-sidebar {
    font-family: "$FONT_NAME";
    font-size: ${FONT_SIZE}px;
}
EOF

# Reload Waybar CSS in-place (no kill/restart needed)
pkill -SIGUSR2 waybar
