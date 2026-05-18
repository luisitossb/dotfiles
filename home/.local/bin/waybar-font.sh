#!/bin/bash
# Cycle through video game fonts for Waybar pixel elements
# Targets: #clock, #pulseaudio, #battery, #custom-sidebar

FONTS=(
    "Press Start 2P|9"
    "Orbitron|9"
    "Silkscreen|9"
    "none|12"
)

STATE_FILE="$HOME/.config/waybar/active-font"
CSS_FILE="$HOME/.config/waybar/themes/glass-center/default/pixel-font.css"

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
NEXT=$(( (CURRENT + 1) % ${#FONTS[@]} ))
echo "$NEXT" > "$STATE_FILE"

ENTRY="${FONTS[$NEXT]}"
FONT_NAME="${ENTRY%|*}"
FONT_SIZE="${ENTRY#*|}"

if [ "$FONT_NAME" = "none" ]; then
    cat > "$CSS_FILE" << 'EOF'
/* no pixel font — using default waybar font */
EOF
else
    cat > "$CSS_FILE" << EOF
#clock,
#pulseaudio,
#battery,
#custom-sidebar {
    font-family: "$FONT_NAME";
    font-size: ${FONT_SIZE}px;
}
EOF
fi

~/.config/waybar/launch.sh
