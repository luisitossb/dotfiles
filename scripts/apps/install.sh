#!/usr/bin/env bash
# scripts/apps/install.sh — Install user-facing applications
# Run as your regular user (NOT root)
#
# Usage:
#   bash scripts/apps/install.sh

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }
trap 'err "scripts/apps/install.sh failed at line $LINENO (exit code: $?). Check output above."; exit 1' ERR

if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}  ✗${NC} Don't run as root."
    exit 1
fi

step "Installing user applications"

APPS=(
    # System monitoring
    mission-center          # GUI system monitor (CPU, RAM, GPU, disk, network)
    btop                    # Terminal resource monitor (btop++)
    nvtop                   # GPU process monitor

    # Browser
    zen-browser-bin         # Zen Browser (Firefox-based, performance-focused)

    # Communication
    discord

    # Music / media
    spotify
    vlc

    # Notes / productivity
    obsidian

    # Downloads
    transmission-gtk             # Torrent client
    yt-dlp                       # CLI video downloader
    open-video-downloader-bin    # GUI for yt-dlp (YouTube / video downloads)

    # Gaming
    steam
    gamemode
    lib32-gamemode
    proton-ge-custom-bin        # Improved Proton — enable in Steam → Settings → Compatibility

    # Remote streaming client
    moonlight-qt                # Connect to a Sunshine host for game streaming

    # Windows compatibility
    wine
    winetricks

    # Network / remote
    tailscale                    # VPN mesh network
    proton-vpn-gtk-app           # ProtonVPN client
    realvnc-vnc-viewer           # VNC client
    kdeconnect                   # Phone ↔ desktop integration
    putty                        # SSH / serial client

    # Fonts
    monocraft                    # Minecraft-style monospace font

    # Utilities
    kitty                        # GPU-accelerated terminal
    meld                         # Visual diff and merge tool
    localsend-bin                # Local file sharing across devices
)

paru -S --needed --noconfirm "${APPS[@]}" || warn "Some packages failed — check output above"

info "All apps installed"
echo ""
echo "  Notes:"
echo "  • Steam: launch and log in, then enable Proton-GE in Settings → Compatibility"
echo "  • Spotify / Discord: log in after first launch"
echo "  • Moonlight: add host → use the Tailscale IP of the machine running Sunshine
  • Tailscale: run 'sudo tailscale up' after install to connect to your network"
echo ""
