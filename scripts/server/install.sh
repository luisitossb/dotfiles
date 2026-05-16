#!/usr/bin/env bash
# scripts/server/install.sh — Install self-hosted server services
# Run as your regular user (NOT root)
#
# Usage:
#   bash scripts/server/install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }

if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}  ✗${NC} Don't run as root."
    exit 1
fi

step "Installing server packages"

SERVER_PKGS=(
    # Media server
    jellyfin-server
    jellyfin-web

    # Game streaming host
    sunshine

    # Containers (for SearXNG and other self-hosted services)
    docker
    docker-compose
)

paru -S --needed --noconfirm "${SERVER_PKGS[@]}" || warn "Some packages failed — check output above"

# ── Services ──────────────────────────────────────────────────────────────────
step "Enabling services"
sudo systemctl enable --now jellyfin && info "Jellyfin enabled"
sudo systemctl enable --now docker && info "Docker enabled"
sudo usermod -aG docker "$USER" && info "Added $USER to docker group"

# ── Jellyfin OSD fix ──────────────────────────────────────────────────────────
step "Installing Jellyfin OSD fix"
if [[ -f "$DOTFILES_DIR/system/jellyfin-osd-fix.sh" ]]; then
    sudo cp "$DOTFILES_DIR/system/jellyfin-osd-fix.sh" /usr/local/bin/
    sudo chmod +x /usr/local/bin/jellyfin-osd-fix.sh
    sudo mkdir -p /etc/pacman.d/hooks
    sudo cp "$DOTFILES_DIR/system/jellyfin-osd-fix.hook" /etc/pacman.d/hooks/
    info "Jellyfin OSD fix installed (auto-applies on every Jellyfin update)"
    if [[ -d /usr/share/jellyfin/web ]]; then
        sudo /usr/local/bin/jellyfin-osd-fix.sh
    fi
else
    warn "system/jellyfin-osd-fix.sh not found — skipping"
fi

# ── Sunshine user service ─────────────────────────────────────────────────────
systemctl --user enable sunshine 2>/dev/null && info "Sunshine user service enabled" \
    || warn "Sunshine service not found — may need a re-login"

info "Server setup done"
echo ""
echo "  Access points after reboot:"
echo "  • Jellyfin  → http://localhost:8096"
echo "  • Sunshine  → https://localhost:47990 (set up credentials on first run)"
echo ""
echo "  Notes:"
echo "  • Re-login or run 'newgrp docker' to use Docker without sudo"
echo "  • Jellyfin: set up media libraries manually after first launch"
echo "  • Sunshine: pair with Moonlight using your Tailscale IP"
echo ""
