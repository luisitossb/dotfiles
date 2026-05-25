#!/usr/bin/env bash
# scripts/kde/install.sh — Install and rice KDE Plasma to match the LuiNux theme
#
# Run this AFTER install.sh (or on an existing install).
# Installs KDE Plasma alongside Hyprland, then applies the full rice:
#   - LuisitoRice color scheme (matugen purple palette)
#   - Kvantum + LuisitoRice Qt theme (transparency + blur)
#   - Klassy window decorations
#   - Kora icons, macOS cursor, Monocraft font
#   - KWin blur + rounded corners
#   - Konsole profile + color scheme
#   - Floating bottom panel (50px)
#
# Usage:
#   bash scripts/kde/install.sh [--rice-only]
#
# Flags:
#   --rice-only   Skip package installs; only apply rice settings.
#                 Use this when KDE is already installed.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }
trap 'err "Failed at line $LINENO (exit $?)"; exit 1' ERR

RICE_ONLY=false
for arg in "$@"; do [[ "$arg" == "--rice-only" ]] && RICE_ONLY=true; done

# ── Install KDE Plasma + required packages ────────────────────────────────────
if [[ "$RICE_ONLY" == "false" ]]; then

    step "Installing KDE Plasma"
    paru -S --needed --noconfirm \
        plasma-meta \
        kde-accessibility-meta \
        kde-graphics-meta \
        kde-multimedia-meta \
        kde-network-meta \
        kde-system-meta \
        kde-utilities-meta \
        qt6-multimedia-ffmpeg \
        phonon-qt6-vlc \
        xdg-desktop-portal-kde \
        || warn "Some Plasma packages failed — check above"

    step "Installing KDE rice packages"
    paru -S --needed --noconfirm \
        klassy \
        kvantum \
        qt6ct \
        kora-icon-theme \
        apple_cursor \
        || warn "Some rice packages failed — check above"

    info "KDE Plasma installed"

fi

# ── Detect if Plasma session is running ──────────────────────────────────────
IN_PLASMA=false
[[ "${XDG_CURRENT_DESKTOP:-}" == "KDE" ]] || [[ "${DESKTOP_SESSION:-}" == "plasma" ]] && IN_PLASMA=true

# ── Deploy KDE-specific files from dotfiles repo ──────────────────────────────
step "Deploying KDE config files"

# Color scheme
mkdir -p ~/.local/share/color-schemes
cp "$DOTFILES_DIR/home/.local/share/color-schemes/LuisitoRice.colors" \
    ~/.local/share/color-schemes/
info "Deployed: LuisitoRice.colors"

# Konsole profile + color scheme
mkdir -p ~/.local/share/konsole
cp "$DOTFILES_DIR/home/.local/share/konsole/LuisitoRice.colorscheme" \
    ~/.local/share/konsole/
cp "$DOTFILES_DIR/home/.local/share/konsole/LuisitoRice.profile" \
    ~/.local/share/konsole/
info "Deployed: Konsole LuisitoRice profile"

# Quickshell toggle desktop entry
mkdir -p ~/.local/share/applications
cp "$DOTFILES_DIR/home/.local/share/applications/toggle-quickshell.desktop" \
    ~/.local/share/applications/ 2>/dev/null || true

# toggle-quickshell.sh
cp "$DOTFILES_DIR/home/.local/bin/toggle-quickshell.sh" ~/.local/bin/
chmod +x ~/.local/bin/toggle-quickshell.sh
info "Deployed: toggle-quickshell.sh"

# Kvantum theme (already symlinked by install.sh — just ensure the active theme is right)
if [[ -d ~/.config/Kvantum/LuisitoRice ]]; then
    kvantummanager --set LuisitoRice 2>/dev/null && info "Kvantum theme: LuisitoRice"
else
    warn "Kvantum/LuisitoRice not found — run install.sh first to symlink config/"
fi

# ── Apply rice settings via kwriteconfig6 ────────────────────────────────────
step "Applying KDE rice settings"

# Color scheme
kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "LuisitoRice"
info "Color scheme: LuisitoRice"

# Widget style (Kvantum)
kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "kvantum"
info "Widget style: kvantum"

# Icons
kwriteconfig6 --file kdeglobals --group "Icons" --key "Theme" "kora"
info "Icons: kora"

# Cursor
kwriteconfig6 --file kdeglobals --group "Mouse" --key "cursorTheme" "macOS"
kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorTheme" "macOS"
info "Cursor: macOS"

# Font (Monocraft 11pt)
kwriteconfig6 --file kdeglobals --group "General" --key "font" \
    "Monocraft,11,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group "General" --key "fixed" \
    "Monocraft,11,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group "General" --key "smallestReadableFont" \
    "Monocraft,8,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group "General" --key "toolBarFont" \
    "Monocraft,10,-1,5,50,0,0,0,0,0"
kwriteconfig6 --file kdeglobals --group "WM" --key "activeFont" \
    "Monocraft,11,-1,5,50,0,0,0,0,0"
info "Font: Monocraft"

# Window decoration (Klassy)
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.klassy"
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "Klassy"
kwriteconfig6 --file kwinrc --group "Klassy Style" --key "cornerRadius" "4"
info "Window decoration: Klassy"

# KWin effects
kwriteconfig6 --file kwinrc --group "Plugins" --key "blurEnabled" "true"
kwriteconfig6 --file kwinrc --group "Plugins" --key "diminactiveEnabled" "false"
kwriteconfig6 --file kwinrc --group "Plugins" --key "kwin4_effect_fadingpopupsEnabled" "true"
kwriteconfig6 --file kwinrc --group "Effect-blur" --key "BlurStrength" "10"
kwriteconfig6 --file kwinrc --group "Effect-roundedcorners" --key "Enabled" "true"
info "KWin effects: blur strength 10, rounded corners"

# Tiling gaps
kwriteconfig6 --file kwinrc --group "Tiling" --key "padding" "8"
info "Tiling gaps: 8px"

# Panel: floating, 50px
kwriteconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel 2" \
    --key "floating" "1"
kwriteconfig6 --file plasmashellrc --group "PlasmaViews" --group "Panel 2" \
    --group "Defaults" --key "thickness" "50"
info "Panel: floating, 50px"

# Konsole default profile
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key "DefaultProfile" \
    "LuisitoRice.profile"
info "Konsole default profile: LuisitoRice"

# ── Apply live (only works inside a running Plasma session) ───────────────────
if [[ "$IN_PLASMA" == "true" ]]; then
    step "Applying changes live"
    plasma-apply-colorscheme LuisitoRice 2>/dev/null && info "Color scheme applied live"
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null && info "KWin reconfigured"
    dbus-send --session --type=method_call \
        --dest=org.kde.KGlobalSettings /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:5 int32:0 2>/dev/null || true
    info "Style change broadcast to running apps"
else
    warn "Not running in a Plasma session — settings written to disk."
    warn "Log into KDE Plasma for changes to take effect."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  KDE rice applied!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  What was set:"
echo "    • Color scheme  — LuisitoRice (matugen purple)"
echo "    • Widget style  — Kvantum / LuisitoRice theme"
echo "    • Decoration    — Klassy (rounded corners)"
echo "    • Icons         — Kora"
echo "    • Cursor        — macOS"
echo "    • Font          — Monocraft 11pt"
echo "    • Blur          — KWin blur strength 10"
echo "    • Panel         — floating, 50px"
echo "    • Konsole       — LuisitoRice profile (dark, transparent)"
echo ""
if [[ "$IN_PLASMA" == "false" ]]; then
    echo "  Log out → select KDE Plasma Wayland in SDDM to see the rice."
    echo ""
fi
