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

# ── Virtual desktops (10 to match Hyprland workspaces) ───────────────────────
step "Configuring virtual desktops"
kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "10"
kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
python3 -c "
import uuid
for i in range(1, 11):
    print(f'Id_{i}={uuid.uuid4()}')
" | while IFS='=' read key val; do
    kwriteconfig6 --file kwinrc --group "Desktops" --key "\$key" "\$val"
done
info "10 virtual desktops"

# ── Keyboard shortcuts — match Hyprland bindings ──────────────────────────────
step "Applying keyboard shortcuts"

# Clear plasmashell conflicts
for i in 1 2 3 4 5 6 7 8 9; do
    kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell" \
        --key "activate task manager entry $i" "none,Meta+$i,Activate Task Manager Entry $i"
done
kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell" \
    --key "manage activities" "none,Meta+Q,Show Activity Switcher"

# Clear kwin conflicts
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Show Desktop" "none,Meta+D,Peek at Desktop"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Edit Tiles" "none,Meta+T,Toggle Tiles Editor"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "view_zoom_in" "none,Meta++=,Zoom In"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "view_zoom_out" "none,Meta+-,Zoom Out"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Walk Through Windows" "Alt+Tab,Alt+Tab,Walk Through Windows"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Walk Through Windows (Reverse)" "Alt+Shift+Tab,Alt+Shift+Tab,Walk Through Windows (Reverse)"

# Window management
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Window Close" "Meta+Q,none,Close Window"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Kill Window" "Meta+Shift+Q,Meta+Ctrl+Esc,Kill Window"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Window Maximize" "Meta+M,Meta+M,Maximize Window"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Window Fullscreen" "Meta+Shift+M,none,Make Window Fullscreen"

# Workspace switching (Meta+1-0, Meta+Shift+1-0, Meta+=/-)
for i in 1 2 3 4 5 6 7 8 9; do
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
        --key "Switch to Desktop $i" "Meta+$i,none,Switch to Desktop $i"
    kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
        --key "Window to Desktop $i" "Meta+Shift+$i,none,Window to Desktop $i"
done
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Window to Desktop 10" "Meta+Shift+0,none,Window to Desktop 10"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Switch to Next Desktop" "Meta+=,none,Switch to Next Desktop"
kwriteconfig6 --file kglobalshortcutsrc --group "kwin" \
    --key "Switch to Previous Desktop" "Meta+-,none,Switch to Previous Desktop"

# App launch shortcuts
kwriteconfig6 --file kglobalshortcutsrc --group "kitty.desktop" \
    --key "_k_friendly_name" "Kitty"
kwriteconfig6 --file kglobalshortcutsrc --group "kitty.desktop" \
    --key "_launch" "Meta+Return,none,Launch Kitty"
kwriteconfig6 --file kglobalshortcutsrc --group "org.gnome.Nautilus.desktop" \
    --key "_k_friendly_name" "Files"
kwriteconfig6 --file kglobalshortcutsrc --group "org.gnome.Nautilus.desktop" \
    --key "_launch" "Meta+E,none,Open File Manager"
kwriteconfig6 --file kglobalshortcutsrc --group "zen.desktop" \
    --key "_k_friendly_name" "Zen Browser"
kwriteconfig6 --file kglobalshortcutsrc --group "zen.desktop" \
    --key "_launch" "Meta+B,none,Open Zen Browser"
kwriteconfig6 --file kglobalshortcutsrc --group "systemsettings.desktop" \
    --key "_k_friendly_name" "System Settings"
kwriteconfig6 --file kglobalshortcutsrc --group "systemsettings.desktop" \
    --key "_launch" "Meta+Escape,none,System Settings"
kwriteconfig6 --file kglobalshortcutsrc --group "org.flameshot.Flameshot.desktop" \
    --key "_k_friendly_name" "Flameshot"
kwriteconfig6 --file kglobalshortcutsrc --group "org.flameshot.Flameshot.desktop" \
    --key "_launch" "Meta+Shift+S,none,Screenshot"
kwriteconfig6 --file kglobalshortcutsrc --group "org.kde.krunner.desktop" \
    --key "_k_friendly_name" "KRunner"
kwriteconfig6 --file kglobalshortcutsrc --group "org.kde.krunner.desktop" \
    --key "_launch" "Meta+D,none,Run Command"

# Clipboard → Meta+F
kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell" \
    --key "show-on-mouse-pos" "Meta+F,Meta+V,Show Clipboard Items at Mouse Position"

info "Shortcuts applied"

# ── Apply live (only works inside a running Plasma session) ───────────────────
if [[ "$IN_PLASMA" == "true" ]]; then
    step "Applying changes live"
    plasma-apply-colorscheme LuisitoRice 2>/dev/null && info "Color scheme applied live"
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null && info "KWin reconfigured"
    dbus-send --session --type=method_call \
        --dest=org.kde.KGlobalSettings /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:5 int32:0 2>/dev/null || true
    info "Style change broadcast to running apps"
    pkill -x kglobalacceld 2>/dev/null; sleep 0.5
    /usr/lib/kglobalacceld &
    info "kglobalacceld restarted — shortcuts active"
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
echo "    • Shortcuts     — Meta+Q/M/1-0/Return/E/B/D/F/Shift+S matching Hyprland"
echo "    • Desktops      — 10 virtual desktops"
echo ""
if [[ "$IN_PLASMA" == "false" ]]; then
    echo "  Log out → select KDE Plasma Wayland in SDDM to see the rice."
    echo ""
fi
