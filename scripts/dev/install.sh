#!/usr/bin/env bash
# scripts/dev/install.sh — Install development tools and runtimes
# Run as your regular user (NOT root)
#
# Usage:
#   bash scripts/dev/install.sh

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }

if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}  ✗${NC} Don't run as root."
    exit 1
fi

step "Installing dev tools"

DEV_PKGS=(
    # Editors
    neovim
    zed

    # JavaScript / Node
    nodejs
    npm

    # Rust
    rustup

    # Python
    python
    python-pip
    python-packaging
    python-pipx

    # Containers
    docker
    docker-compose

    # Git / GitHub
    github-cli
)

paru -S --needed --noconfirm "${DEV_PKGS[@]}" || warn "Some packages failed — check output above"

# ── Rustup default toolchain ──────────────────────────────────────────────────
if command -v rustup &>/dev/null; then
    rustup default stable && info "Rust stable toolchain set"
fi

# ── Docker group ──────────────────────────────────────────────────────────────
sudo usermod -aG docker "$USER" && info "Added $USER to docker group (re-login to take effect)"

# ── Docker service ────────────────────────────────────────────────────────────
sudo systemctl enable --now docker && info "Docker service enabled"

info "Dev tools installed"
echo ""
echo "  Notes:"
echo "  • Re-login or run 'newgrp docker' to use Docker without sudo"
echo "  • GitHub CLI: run 'gh auth login' to authenticate"
echo ""
