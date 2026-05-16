#!/usr/bin/env bash
# install-apps.sh — Install user applications on an existing CachyOS setup
# Run as your regular user (NOT root)
#
# Usage:
#   bash install-apps.sh

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }

if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}  ✗${NC} Don't run as root."
    exit 1
fi

step "Installing applications"

APPS=(
    # Communication
    discord
    telegram-desktop

    # Music / media
    spotify
    vlc

    # Notes / productivity
    obsidian

    # Torrents
    qbittorrent

    # Gaming
    steam
    gamemode
    lib32-gamemode
    proton-ge-custom-bin

    # Dev
    neovim
    zed

    # Utilities
    localsend-bin
    wine
    winetricks
)

paru -S --needed --noconfirm "${APPS[@]}" || warn "Some packages failed — check output above"

info "All apps installed"
echo ""
echo "  Notes:"
echo "  • Steam: launch and log in, then enable Proton-GE in Settings → Compatibility"
echo "  • Spotify / Opera GX: log in after first launch"
echo ""
