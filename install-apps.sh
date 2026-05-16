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
    # System monitoring
    mission-center      # GUI system monitor (CPU, RAM, GPU, disk, network)
    btop                # Terminal resource monitor (btop++)
    nvtop               # GPU process monitor

    # Browser
    zen-browser-bin     # Zen Browser (Firefox-based, performance-focused)

    # Communication
    discord
    telegram-desktop

    # Music / media
    spotify
    vlc                 # Media player

    # Notes / productivity
    obsidian            # Markdown knowledge base

    # Downloads
    qbittorrent                     # Torrent client
    open-video-downloader-bin       # GUI for yt-dlp (YouTube / video downloads)

    # Gaming
    steam
    gamemode
    lib32-gamemode
    proton-ge-custom-bin            # Improved Proton for Steam — enable in Settings → Compatibility

    # Remote access / game streaming
    sunshine                        # Game stream host (run on this machine, connect via Moonlight)
    moonlight-qt                    # Game stream client (connect to another Sunshine host)

    # Windows compatibility
    wine
    winetricks

    # Dev
    zed                             # Zed code editor

    # Utilities
    localsend-bin                   # Local file sharing across devices
)

paru -S --needed --noconfirm "${APPS[@]}" || warn "Some packages failed — check output above"

info "All apps installed"
echo ""
echo "  Notes:"
echo "  • Steam: launch and log in, then enable Proton-GE in Settings → Compatibility"
echo "  • Spotify / Discord: log in after first launch"
echo "  • Sunshine: web UI at https://localhost:47990 — set up credentials on first run"
echo "  • Moonlight: add host → use the Tailscale IP of the machine running Sunshine"
echo ""
