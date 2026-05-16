#!/usr/bin/env bash
# scripts/server/install-ai.sh — Install local AI stack (Ollama + Open WebUI)
# Run as your regular user (NOT root)
#
# Usage:
#   bash scripts/server/install-ai.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }
trap 'err "scripts/server/install-ai.sh failed at line $LINENO (exit code: $?). Check output above."; exit 1' ERR

if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}  ✗${NC} Don't run as root."
    exit 1
fi

# ── Detect GPU ────────────────────────────────────────────────────────────────
step "Detecting GPU"
GPU="cpu"
lspci 2>/dev/null | grep -qi "nvidia" && GPU="nvidia"
lspci 2>/dev/null | grep -Eqi "amd|radeon" && GPU="amd"
info "GPU: $GPU"

# ── Ollama ────────────────────────────────────────────────────────────────────
step "Installing Ollama"

case "$GPU" in
    nvidia) paru -S --needed --noconfirm ollama-cuda && info "Ollama (CUDA/NVIDIA) installed" ;;
    amd)    paru -S --needed --noconfirm ollama-rocm && info "Ollama (ROCm/AMD) installed" \
                || { warn "ROCm install failed — falling back to CPU-only Ollama"; paru -S --needed --noconfirm ollama; } ;;
    *)      paru -S --needed --noconfirm ollama && info "Ollama (CPU-only) installed" ;;
esac

# ── Ollama tuning ─────────────────────────────────────────────────────────────
step "Tuning Ollama"
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_KEEP_ALIVE=5s"
EOF
sudo systemctl daemon-reload
info "Ollama: max 1 model loaded, 5s VRAM keep-alive, 1 parallel request"

sudo systemctl enable --now ollama && info "Ollama service enabled"

# ── Open WebUI ────────────────────────────────────────────────────────────────
step "Installing Open WebUI"

if command -v pipx &>/dev/null; then
    pipx install open-webui && info "Open WebUI installed via pipx"
else
    pip install --user open-webui && info "Open WebUI installed via pip"
fi

# Deploy service file
SERVICE_SRC="$DOTFILES_DIR/home/.config/systemd/user/open-webui.service"
if [[ -f "$SERVICE_SRC" ]]; then
    mkdir -p ~/.config/systemd/user
    cp "$SERVICE_SRC" ~/.config/systemd/user/open-webui.service
    sed -i "s|/home/luisito|$HOME|g" ~/.config/systemd/user/open-webui.service
    info "Deployed: open-webui.service"
else
    warn "open-webui.service not found in dotfiles — skipping service deployment"
fi

systemctl --user daemon-reload
systemctl --user enable --now open-webui && info "Open WebUI service enabled" \
    || warn "Could not enable open-webui service — check: systemctl --user status open-webui"

# ── Models ────────────────────────────────────────────────────────────────────
step "Pulling models"
echo "  Pulling nomic-embed-text (embedding model for RAG — small, required for Open WebUI RAG)"
ollama pull nomic-embed-text && info "nomic-embed-text pulled"

echo ""
echo "  Suggested chat models (pick based on your VRAM):"
echo "    llama3.1:8b       — general purpose, ~5GB VRAM"
echo "    qwen2.5-coder:7b  — coding, ~4.5GB VRAM"
echo "    llama3.1:70b      — high quality, needs 40GB+ VRAM or will run on CPU"
echo ""
echo "  Pull manually with:  ollama pull <model>"
echo "  List installed:      ollama list"

# ── Done ──────────────────────────────────────────────────────────────────────
info "AI stack installed"
echo ""
echo "  Access:"
echo "  • Open WebUI → http://localhost:8080"
echo "  • Ollama API → http://localhost:11434"
echo ""
echo "  Notes:"
echo "  • Open WebUI has RAG + SearXNG web search pre-configured in the service"
echo "  • SearXNG (optional, for web search in Open WebUI):"
echo "      docker run -d --name searxng -p 8888:8080 --restart unless-stopped searxng/searxng:latest"
echo "  • To restart Open WebUI:  systemctl --user restart open-webui"
echo "  • Logs:                   journalctl --user -u open-webui -f"
echo ""
