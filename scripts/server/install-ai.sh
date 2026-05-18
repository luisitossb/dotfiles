#!/usr/bin/env bash
# scripts/server/install-ai.sh — Install local AI stack
# Ollama + Open WebUI (Docker) + ComfyUI/FLUX (Docker) + SearXNG (Docker)
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
trap 'err "install-ai.sh failed at line $LINENO (exit code: $?). Check output above."; exit 1' ERR

if [[ "$EUID" -eq 0 ]]; then
    err "Don't run as root."
    exit 1
fi

# ── Detect GPU ────────────────────────────────────────────────────────────────
step "Detecting GPU"
GPU="cpu"
lspci 2>/dev/null | grep -qi "nvidia" && GPU="nvidia"
lspci 2>/dev/null | grep -Eqi "amd|radeon" && GPU="amd"
info "GPU: $GPU"

# ── Docker (required for Open WebUI + ComfyUI) ────────────────────────────────
step "Ensuring Docker is installed"
if ! command -v docker &>/dev/null; then
    paru -S --needed --noconfirm docker docker-compose
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    warn "Added $USER to docker group — run 'newgrp docker' or re-login before continuing"
else
    info "Docker already installed"
fi

# ── nvidia-container-toolkit (NVIDIA only — required for GPU in Docker) ───────
if [[ "$GPU" == "nvidia" ]]; then
    step "Installing nvidia-container-toolkit"
    paru -S --needed --noconfirm nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    info "nvidia-container-toolkit installed and configured"
fi

# ── Ollama ────────────────────────────────────────────────────────────────────
step "Installing Ollama"
case "$GPU" in
    nvidia) paru -S --needed --noconfirm ollama-cuda && info "Ollama (CUDA/NVIDIA) installed" ;;
    amd)    paru -S --needed --noconfirm ollama-rocm && info "Ollama (ROCm/AMD) installed" \
                || { warn "ROCm failed — falling back to CPU"; paru -S --needed --noconfirm ollama; } ;;
    *)      paru -S --needed --noconfirm ollama && info "Ollama (CPU-only) installed" ;;
esac

step "Tuning Ollama"
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_KEEP_ALIVE=5s"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_CTX=8192"
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ollama
info "Ollama tuned: host=0.0.0.0, keep-alive=5s, max 1 model, 8192 ctx"

# ── UFW rule — allow Docker bridge to reach Ollama on host ────────────────────
step "Configuring firewall for Docker → Ollama"
sudo ufw allow from 172.17.0.0/16 to any port 11434 comment "Docker → Ollama" 2>/dev/null \
    && info "UFW: Docker bridge allowed to reach Ollama" \
    || warn "UFW rule failed — Open WebUI may not reach Ollama"

# ── SearXNG (web search for Open WebUI) ──────────────────────────────────────
step "Starting SearXNG"
docker rm -f searxng 2>/dev/null || true
docker run -d \
    --name searxng \
    --restart unless-stopped \
    -p 8888:8080 \
    searxng/searxng:latest
sudo ufw allow from 172.17.0.0/16 to any port 8888 comment "Docker → SearXNG" 2>/dev/null || true
info "SearXNG running on port 8888"

# ── Open WebUI (Docker) ───────────────────────────────────────────────────────
step "Deploying Open WebUI service"
SERVICE_SRC="$DOTFILES_DIR/home/.config/systemd/user/open-webui.service"
if [[ -f "$SERVICE_SRC" ]]; then
    mkdir -p ~/.config/systemd/user
    cp "$SERVICE_SRC" ~/.config/systemd/user/open-webui.service
    info "Deployed: open-webui.service"
else
    warn "open-webui.service not found in dotfiles — skipping"
fi

systemctl --user daemon-reload
systemctl --user enable --now open-webui \
    && info "Open WebUI service enabled" \
    || warn "Could not enable open-webui — check: systemctl --user status open-webui"

# ── ComfyUI + FLUX (Docker, NVIDIA only) ─────────────────────────────────────
if [[ "$GPU" == "nvidia" ]]; then
    step "Deploying ComfyUI service (FLUX image generation)"

    # Create model directories
    mkdir -p ~/.comfyui/models/{unet,vae,clip,checkpoints} ~/.comfyui/{custom_nodes,output}

    # Deploy service file
    COMFY_SRC="$DOTFILES_DIR/home/.config/systemd/user/comfyui.service"
    if [[ -f "$COMFY_SRC" ]]; then
        cp "$COMFY_SRC" ~/.config/systemd/user/comfyui.service
        info "Deployed: comfyui.service"
    else
        warn "comfyui.service not found in dotfiles — skipping"
    fi

    systemctl --user daemon-reload
    systemctl --user enable comfyui \
        && info "ComfyUI service enabled (won't start until FLUX models are downloaded)" \
        || warn "Could not enable comfyui service"

    echo ""
    echo "  FLUX.1-schnell models needed in ~/.comfyui/models/:"
    echo "    unet/flux1-schnell-Q4_K_S.gguf"
    echo "    vae/ae.safetensors"
    echo "    clip/t5xxl_fp8_e4m3fn.safetensors"
    echo "    clip/clip_l.safetensors"
    echo "  Then: systemctl --user start comfyui"
    echo "  Upload workflow: ~/flux-schnell-workflow.json → Open WebUI admin → Images"
else
    warn "ComfyUI skipped — NVIDIA GPU required for FLUX image generation"
fi

# ── OpenCode (AI terminal agent) ──────────────────────────────────────────────
step "Installing OpenCode"
if ! command -v opencode &>/dev/null; then
    curl -fsSL https://opencode.ai/install | bash \
        && info "OpenCode installed" \
        || warn "OpenCode install failed — install manually from opencode.ai"
else
    info "OpenCode already installed"
fi

# ── Models ────────────────────────────────────────────────────────────────────
step "Pulling Ollama models"
ollama pull nomic-embed-text && info "nomic-embed-text pulled (RAG embeddings)"
ollama pull gemma3:12b      && info "gemma3:12b pulled (Open WebUI default, Researcher)"
ollama pull qwen2.5-coder:7b && info "qwen2.5-coder:7b pulled (Code Reader)"
ollama pull qwen3.5:9b      && info "qwen3.5:9b pulled (OpenCode local fallback)"

# ── Done ──────────────────────────────────────────────────────────────────────
info "AI stack installed"
echo ""
echo "  Access:"
echo "  • Open WebUI  → http://localhost:8080"
echo "  • Ollama API  → http://localhost:11434"
echo "  • ComfyUI     → http://localhost:8188 (NVIDIA only, after model download)"
echo "  • SearXNG     → http://localhost:8888"
echo ""
echo "  OpenCode: run 'opencode' in any project directory"
echo "  Default model: opencode/deepseek-v4-flash-free (free, cloud)"
echo "  Local fallback: ollama/qwen3.5:9b"
echo ""
