#!/bin/bash
# Cycle through video game fonts for Waybar + Quickshell
# Waybar targets: #clock, #pulseaudio, #battery, #custom-sidebar
# Quickshell target: Theme.fontFamily in CustomTheme/Theme.qml

FONTS=(
    "Press Start 2P|9"
    "Orbitron|9"
    "Silkscreen|9"
)

STATE_FILE="$HOME/.config/waybar/active-font"
CSS_FILE="$HOME/.config/waybar/themes/glass-center/default/pixel-font.css"
THEME_QML="$HOME/.config/quickshell/CustomTheme/Theme.qml"

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
NEXT=$(( (CURRENT + 1) % ${#FONTS[@]} ))
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

# Update Quickshell theme font
sed -i "s/readonly property string fontFamily: \".*\"/readonly property string fontFamily: \"$FONT_NAME\"/" "$THEME_QML"

# Reload both
~/.config/waybar/launch.sh
killall quickshell 2>/dev/null
sleep 0.3
quickshell &
