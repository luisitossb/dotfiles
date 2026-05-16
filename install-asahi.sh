#!/usr/bin/env bash
# install-asahi.sh — Bootstrap Asahi Linux (Arch ARM) on Apple Silicon to match LuiNux
# Adapted from install.sh — strips CachyOS-specific packages, GPU drivers, Limine, battery service
#
# Prerequisites:
#   1. Run the Asahi Linux installer from macOS first:
#      curl https://alx.sh | sh
#   2. Boot into Asahi, connect to WiFi, then:
#      git clone https://github.com/luisitossb/dotfiles.git ~/dotfiles
#      cd ~/dotfiles && bash install-asahi.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }

confirm() {
    read -rp "$(echo -e "${YELLOW}  ?${NC} $1 [y/N] ")" yn
    [[ "$yn" =~ ^[Yy]$ ]]
}

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
    err "Don't run as root. Run as your regular user."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    err "This script is for Arch-based systems only (Asahi Linux)."
    exit 1
fi

# Warn if not running on Apple Silicon
if ! uname -m | grep -q "aarch64"; then
    warn "This script is intended for Apple Silicon (aarch64). Current arch: $(uname -m)"
    confirm "Continue anyway?" || exit 1
fi

# ── Parse flags ───────────────────────────────────────────────────────────────
DOTFILES_ONLY=false
for arg in "$@"; do
    [[ "$arg" == "--dotfiles-only" ]] && DOTFILES_ONLY=true
done

step "Starting LuiNux setup for Asahi Linux (Apple Silicon)"
echo "  Dotfiles: $DOTFILES_DIR"
echo "  User:     $USER"
if [[ "$DOTFILES_ONLY" == "true" ]]; then
    echo ""
    warn "Dotfiles-only mode — skipping package installs, services, and system config."
fi
echo ""
warn "NOTE: GPU drivers are managed by Asahi — do NOT install mesa/vulkan manually."
warn "NOTE: No Ollama GPU acceleration on Apple Silicon — CPU inference only."
warn "NOTE: eww GPU widgets (VRAM/GPU temp) won't work — remove them after setup."

# ── Base packages ─────────────────────────────────────────────────────────────
step "Installing base packages"

BASE_PKGS=(
    # System base
    base base-devel git wget curl sudo nano vim

    # Boot / filesystem
    btrfs-progs efibootmgr

    # Wayland / Hyprland
    hyprland hypridle hyprlock hyprpaper hyprpicker hyprsunset
    xdg-desktop-portal-hyprland xdg-user-dirs xorg-xwayland uwsm

    # Waybar + notifications
    waybar swaync

    # Launchers
    rofi quickshell

    # Terminal + shell
    kitty zsh bash-completion

    # Fonts
    ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-meslo-nerd
    ttf-font-awesome noto-fonts noto-fonts-emoji noto-fonts-cjk
    otf-font-awesome awesome-terminal-fonts
    ttf-bitstream-vera ttf-dejavu ttf-liberation ttf-opensans

    # Audio
    pipewire-alsa pipewire-pulse wireplumber pavucontrol
    alsa-firmware alsa-plugins alsa-utils sof-firmware

    # Network
    networkmanager networkmanager-openvpn network-manager-applet iwd

    # Bluetooth
    bluez bluez-utils bluez-libs blueman

    # Login manager
    sddm

    # Power / hardware
    power-profiles-daemon upower brightnessctl cpupower

    # Screenshot / clipboard
    cliphist wl-clipboard grim slurp

    # Theming
    nwg-look nwg-displays qt6ct qt6-virtualkeyboard
    gnome-themes-extra breeze

    # System tools
    btop fastfetch duf pv rsync
    playerctl udiskie ufw inotify-tools
    ripgrep fd bat

    # Widgets / visualizers
    cava

    # Media / files
    nautilus dolphin gvfs gvfs-mtp tumbler
    ffmpegthumbnailer loupe vlc
    gst-libav gst-plugin-pipewire gst-plugins-bad gst-plugins-ugly

    # Apps
    discord obsidian qbittorrent flatpak
    polkit-gnome polkit-kde-agent

    # Dev tools
    neovim nodejs npm rustup
    python python-pip python-packaging python-pipx
    docker docker-compose github-cli

    # AI (CPU only on Apple Silicon)
    ollama

    # Python extras
    matugen

    # Misc
    unrar unzip openssh nss-mdns avahi
)

sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}" || warn "Some base packages failed — check output above"

# ── No CPU microcode needed ───────────────────────────────────────────────────
# Apple Silicon uses ARM — intel-ucode and amd-ucode don't apply here.

# ── No GPU driver install needed ──────────────────────────────────────────────
# Asahi Linux ships its own GPU driver (AGX/Honeykrisp) as part of the kernel.
# Installing mesa from standard Arch repos would conflict. Leave GPU alone.

# ── AUR packages ──────────────────────────────────────────────────────────────
step "Installing AUR packages"

if ! command -v paru &>/dev/null; then
    info "Installing paru..."
    git clone https://aur.archlinux.org/paru.git /tmp/paru-build
    (cd /tmp/paru-build && makepkg -si --noconfirm)
fi

AUR_PKGS=(
    apple_cursor
    sddm-astronaut-theme
    grimblast-git
    pokemon-colorscripts-git
    python-pywalfox
    localsend-bin
    waypaper
    eww
    # opera-gx        — no ARM build, skipped
    # zen-browser-bin — check https://github.com/zen-browser/desktop for ARM releases
    #                   if unavailable, use: sudo pacman -S firefox
)

paru -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages failed — check output above"

# Browser notice
step "Browser"
warn "Zen Browser may not have an ARM Linux build yet."
warn "Check: https://github.com/zen-browser/desktop/releases"
warn "If no aarch64 release exists, install Firefox instead:"
warn "  sudo pacman -S firefox"
if confirm "Install Firefox as fallback browser now?"; then
    sudo pacman -S --needed --noconfirm firefox && info "Firefox installed"
fi

# ── Open WebUI ────────────────────────────────────────────────────────────────
step "Installing Open WebUI (Ollama frontend)"
pipx install open-webui && info "Open WebUI installed via pipx" \
    || pip install --user open-webui && info "Open WebUI installed via pip"

# ── Dotfiles ──────────────────────────────────────────────────────────────────
step "Deploying dotfiles"

mkdir -p ~/.config ~/.local/bin ~/.config/systemd/user

for dir_path in "$DOTFILES_DIR/config/"/*/; do
    dir_name=$(basename "$dir_path")
    cp -r "$dir_path" ~/.config/
    info "Deployed: ~/.config/$dir_name"
done

[[ -f "$DOTFILES_DIR/home/.zshrc_custom" ]] && \
    cp "$DOTFILES_DIR/home/.zshrc_custom" ~/ && info "Deployed: ~/.zshrc_custom"

if [[ -d "$DOTFILES_DIR/home/.local/bin" ]]; then
    cp "$DOTFILES_DIR/home/.local/bin/"* ~/.local/bin/
    chmod +x ~/.local/bin/*
    info "Deployed: ~/.local/bin scripts"
fi

if [[ -f "$DOTFILES_DIR/home/.config/systemd/user/open-webui.service" ]]; then
    cp "$DOTFILES_DIR/home/.config/systemd/user/open-webui.service" ~/.config/systemd/user/
    sed -i "s|/home/luisito|$HOME|g" ~/.config/systemd/user/open-webui.service
    info "Deployed: open-webui.service"
fi

if ! grep -q "zshrc_custom" ~/.zshrc 2>/dev/null; then
    echo '[[ -f ~/.zshrc_custom ]] && source ~/.zshrc_custom' >> ~/.zshrc
    info "Linked .zshrc_custom in .zshrc"
fi

# Fix hardcoded /home/luisito paths in deployed configs
sed -i "s|/home/luisito|$HOME|g" ~/.config/waybar/themes/ml4w-glass-center/default/style.css 2>/dev/null && info "Fixed waybar CSS path"

# ── Bluetooth: off by default ─────────────────────────────────────────────────
step "Configuring Bluetooth"
sudo sed -i 's/#AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf \
    || sudo sed -i 's/AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
info "Bluetooth auto-enable disabled"

# ── Services ──────────────────────────────────────────────────────────────────
step "Enabling system services"

SYSTEM_SVCS=(
    NetworkManager
    bluetooth
    ollama
    sddm
    docker
    ufw
    avahi-daemon
    power-profiles-daemon
)
for svc in "${SYSTEM_SVCS[@]}"; do
    sudo systemctl enable "$svc" 2>/dev/null \
        && info "Enabled: $svc" \
        || warn "Could not enable: $svc"
done

step "Enabling user services"
systemctl --user daemon-reload
USER_SVCS=(open-webui wireplumber pipewire pipewire-pulse)
for svc in "${USER_SVCS[@]}"; do
    systemctl --user enable "$svc" 2>/dev/null \
        && info "Enabled (user): $svc" \
        || warn "Could not enable (user): $svc"
done

# ── Firewall ──────────────────────────────────────────────────────────────────
step "Configuring firewall"
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
info "UFW enabled"

# ── Docker group ──────────────────────────────────────────────────────────────
sudo usermod -aG docker "$USER" && info "Added $USER to docker group"

# ── Ollama tuning (CPU mode) ──────────────────────────────────────────────────
step "Configuring Ollama (CPU-only on Apple Silicon)"
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_KEEP_ALIVE=5s"
EOF
sudo systemctl daemon-reload
info "Ollama: max 1 model loaded, 5s keep-alive"

# ── SDDM theme ────────────────────────────────────────────────────────────────
step "Configuring SDDM"
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=sddm-astronaut-theme
EOF
info "SDDM theme set"

# ── Battery charge limit — SKIPPED ───────────────────────────────────────────
# Apple Silicon battery management is handled by Asahi's kernel and firmware.
# The BAT0 sysfs path used in install.sh does not apply here.

# ── Limine bootloader — SKIPPED ──────────────────────────────────────────────
# Asahi Linux uses its own boot process. Do not touch the bootloader.

# ── ml4w ─────────────────────────────────────────────────────────────────────
step "Manual step required: ml4w"
echo "  ml4w needs to be installed separately after reboot."
echo "  It provides scripts in ~/.config/ml4w/ that waybar and autostart depend on."
echo ""
echo "  Install via yay:"
echo "    paru -S ml4w-hyprland"
echo ""
echo "  Then re-run dotfiles deployment to overlay your configs on top of ml4w defaults:"
echo "    cd ~/dotfiles && bash install-asahi.sh --dotfiles-only"

# ── Zen browser ──────────────────────────────────────────────────────────────
step "Set default browser"
echo "  If Zen Browser ARM is available and installed:"
echo "    echo 'zen-browser' > ~/.config/ml4w/settings/browser.sh"
echo "  Otherwise with Firefox:"
echo "    echo 'firefox' > ~/.config/ml4w/settings/browser.sh"

# ── eww GPU widget warning ────────────────────────────────────────────────────
step "Post-install: eww dashboard GPU widgets"
echo "  The eww dashboard has VRAM and GPU temp widgets that use nvidia-smi."
echo "  On Apple Silicon these will fail silently — remove them from eww.yuck:"
echo ""
echo "  In ~/.config/eww/eww.yuck, delete or comment out:"
echo "    (defpoll vram_usage ...)   — the nvidia-smi VRAM poll"
echo "    (defpoll gpu_temp ...)     — the nvidia-smi GPU temp poll"
echo "    The stat-row for VRAM in the dashboard widget"
echo ""
echo "  Everything else (CPU, RAM, disk, network, volume, battery, now-playing) works fine."

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Done! Reboot to finish.${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  After reboot:"
echo "  • Install ml4w (paru -S ml4w-hyprland), then reboot again"
echo "  • Re-run install-asahi.sh to overlay dotfiles over ml4w defaults"
echo "  • Set your default browser in ~/.config/ml4w/settings/browser.sh"
echo "  • Remove eww GPU widgets from ~/.config/eww/eww.yuck"
echo "  • Open WebUI → http://localhost:8080 (Ollama CPU mode)"
echo ""
