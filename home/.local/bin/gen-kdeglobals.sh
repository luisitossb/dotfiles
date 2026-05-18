#!/usr/bin/env bash
# Generate ~/.config/kdeglobals from matugen colors.json
COLORS="$HOME/.config/quickshell/colors/colors.json"
OUT="$HOME/.config/kdeglobals"

hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

surface=$(jq -r '.surface' "$COLORS")
surface_low=$(jq -r '.surface_container_low' "$COLORS")
surface_container=$(jq -r '.surface_container' "$COLORS")
surface_high=$(jq -r '.surface_container_high' "$COLORS")
surface_highest=$(jq -r '.surface_container_highest' "$COLORS")
on_surface=$(jq -r '.on_surface' "$COLORS")
on_surface_variant=$(jq -r '.on_surface_variant' "$COLORS")
primary=$(jq -r '.primary' "$COLORS")
primary_container=$(jq -r '.primary_container' "$COLORS")
on_primary=$(jq -r '.on_primary' "$COLORS")
error=$(jq -r '.error' "$COLORS")

cat > "$OUT" << EOF
[Colors:Button]
BackgroundNormal=$(hex_to_rgb "$surface_container")
BackgroundAlternate=$(hex_to_rgb "$surface_high")
ForegroundNormal=$(hex_to_rgb "$on_surface")
ForegroundInactive=$(hex_to_rgb "$on_surface_variant")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$primary")

[Colors:Complementary]
BackgroundNormal=$(hex_to_rgb "$surface_highest")
ForegroundNormal=$(hex_to_rgb "$on_surface")

[Colors:Header]
BackgroundNormal=$(hex_to_rgb "$surface_low")
BackgroundAlternate=$(hex_to_rgb "$surface_container")
ForegroundNormal=$(hex_to_rgb "$on_surface")
ForegroundInactive=$(hex_to_rgb "$on_surface_variant")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$primary")

[Colors:Selection]
BackgroundNormal=$(hex_to_rgb "$primary")
BackgroundAlternate=$(hex_to_rgb "$primary_container")
ForegroundNormal=$(hex_to_rgb "$on_primary")
ForegroundInactive=$(hex_to_rgb "$on_surface_variant")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$primary")

[Colors:Tooltip]
BackgroundNormal=$(hex_to_rgb "$surface_high")
ForegroundNormal=$(hex_to_rgb "$on_surface")

[Colors:View]
BackgroundNormal=$(hex_to_rgb "$surface")
BackgroundAlternate=$(hex_to_rgb "$surface_low")
ForegroundNormal=$(hex_to_rgb "$on_surface")
ForegroundInactive=$(hex_to_rgb "$on_surface_variant")
ForegroundLink=$(hex_to_rgb "$primary")
ForegroundNegative=$(hex_to_rgb "$error")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$primary")

[Colors:Window]
BackgroundNormal=$(hex_to_rgb "$surface_low")
BackgroundAlternate=$(hex_to_rgb "$surface_container")
ForegroundNormal=$(hex_to_rgb "$on_surface")
ForegroundInactive=$(hex_to_rgb "$on_surface_variant")
DecorationFocus=$(hex_to_rgb "$primary")
DecorationHover=$(hex_to_rgb "$primary")

[General]
ColorScheme=MatugenDark
Name=Matugen Dark
shadeSortColumn=true

[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
contrast=4
widgetStyle=kvantum
EOF

echo "kdeglobals updated"

# Also update MatugenDark Kvantum GeneralColors to stay in sync
surface_bright=$(jq -r '.surface_bright' "$COLORS")
outline=$(jq -r '.outline' "$COLORS")
tertiary=$(jq -r '.tertiary' "$COLORS")
on_surface_variant2=$(jq -r '.on_surface_variant' "$COLORS")

KVCONFIG="$HOME/.config/Kvantum/MatugenDark/MatugenDark.kvconfig"
python3 - << PYEOF
import re

with open("$KVCONFIG") as f:
    content = f.read()

new_section = """[GeneralColors]
window.color=$surface_low
inactive.window.color=$surface_low
base.color=$surface
inactive.base.color=$surface_low
alt.base.color=$surface_container
inactive.alt.base.color=$surface_container
button.color=$surface_container
light.color=$surface_bright
mid.light.color=$surface_highest
dark.color=$surface_high
mid.color=$surface_container
highlight.color=$primary
inactive.highlight.color=$primary
text.color=$on_surface
inactive.text.color=$on_surface_variant2
window.text.color=$on_surface
inactive.window.text.color=$on_surface_variant2
button.text.color=$on_surface
disabled.text.color=$outline
tooltip.text.color=$on_surface
highlight.text.color=$on_primary
link.color=$primary
link.visited.color=$tertiary
progress.indicator.text.color=$on_primary

"""

content = re.sub(r'\[GeneralColors\]\n.*?\n(?=\[)', new_section, content, flags=re.DOTALL)

with open("$KVCONFIG", "w") as f:
    f.write(content)

print("MatugenDark Kvantum colors updated")
PYEOF
