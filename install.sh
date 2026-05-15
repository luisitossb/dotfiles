#!/usr/bin/env bash
# install.sh — Bootstrap a fresh CachyOS install to match luisito's setup
# Run as your user (NOT root) after a fresh CachyOS base install
#
# Usage:
#   git clone https://github.com/luisitossb/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && bash install.sh
#
# Flags:
#   --dotfiles-only   Skip all package installs; only deploy configs + system files.
#                     Use after a second ml4w install to overlay dotfiles on top.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="https://github.com/luisitossb/dotfiles.git"

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

# ── Parse flags ───────────────────────────────────────────────────────────────
DOTFILES_ONLY=false
if [[ "${1:-}" == "--dotfiles-only" ]]; then
    DOTFILES_ONLY=true
fi

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
    err "Don't run as root. Run as your regular user."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    err "This script is for Arch/CachyOS only."
    exit 1
fi

step "Starting luisito setup"
echo "  Dotfiles: $DOTFILES_DIR"
echo "  User:     $USER"
if [[ "$DOTFILES_ONLY" == "true" ]]; then
    echo ""
    warn "Dotfiles-only mode — skipping package installs, services, and system config."
    warn "Only deploying configs, scripts, and system files (Jellyfin hook, etc.)"
fi

# ── Hardware detection ────────────────────────────────────────────────────────
step "Detecting hardware"

GPU="intel"
if lspci 2>/dev/null | grep -qi "nvidia"; then
    GPU="nvidia"
elif lspci 2>/dev/null | grep -Eqi "amd|radeon"; then
    GPU="amd"
fi

CPU="intel"
if grep -qi "amd" /proc/cpuinfo; then
    CPU="amd"
fi

HYBRID=false
if lspci 2>/dev/null | grep -Eqi "intel.*(vga|graphics|display)" && [[ "$GPU" != "intel" ]]; then
    HYBRID=true
fi

IS_LAPTOP=false
if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
    IS_LAPTOP=true
fi

info "GPU: $GPU  |  CPU: $CPU  |  Hybrid iGPU: $HYBRID  |  Laptop: $IS_LAPTOP"

# ── Base packages ─────────────────────────────────────────────────────────────
if [[ "$DOTFILES_ONLY" == "false" ]]; then

step "Installing base packages"

BASE_PKGS=(
    # System base
    base base-devel git wget curl sudo nano vim

    # CachyOS specific
    cachyos-hello cachyos-hooks cachyos-kernel-manager cachyos-settings
    cachyos-rate-mirrors cachyos-zsh-config cachyos-fish-config
    cachyos-snapper-support cachyos-plymouth-theme cachyos-plymouth-bootanimation
    cachyos-packageinstaller chwd

    # Boot / filesystem
    limine limine-mkinitcpio-hook limine-snapper-sync
    btrfs-progs btrfs-assistant snapper
    efibootmgr efitools

    # Wayland / Hyprland
    hyprland hypridle hyprlock hyprpaper hyprpicker hyprsunset
    xdg-desktop-portal-hyprland xdg-user-dirs xorg-xwayland uwsm

    # Waybar + notifications
    waybar swaync

    # Launchers
    rofi wofi quickshell

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
    switcheroo-control

    # Screenshot / clipboard
    cliphist wl-clipboard grim slurp

    # Theming
    nwg-look nwg-displays qt6ct qt6-virtualkeyboard
    gnome-themes-extra breeze

    # System tools
    btop htop fastfetch duf pv rsync
    playerctl udiskie ufw inotify-tools
    ripgrep fd bat

    # Widgets / visualizers
    eww cava

    # Media / files
    nautilus dolphin gvfs gvfs-mtp tumbler
    ffmpegthumbnailer loupe vlc
    gst-libav gst-plugin-pipewire gst-plugins-bad gst-plugins-ugly

    # Apps
    discord obsidian qbittorrent flatpak
    polkit-gnome polkit-kde-agent

    # Dev tools
    neovim zed nodejs npm rustup
    python python-pip python-packaging python-pipx
    docker docker-compose github-cli

    # AI / media services
    ollama jellyfin-server jellyfin-web

    # Python extras
    matugen

    # Gaming (multilib must be enabled — CachyOS enables it by default)
    steam gamemode lib32-gamemode

    # Misc
    wine winetricks unrar unzip
    openssh nss-mdns avahi
)

sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}" || warn "Some base packages failed — check output above"

# ── CPU microcode ─────────────────────────────────────────────────────────────
step "Installing CPU microcode ($CPU)"
if [[ "$CPU" == "intel" ]]; then
    sudo pacman -S --needed --noconfirm intel-ucode && info "Intel microcode installed"
else
    sudo pacman -S --needed --noconfirm amd-ucode && info "AMD microcode installed"
fi

# ── GPU drivers ───────────────────────────────────────────────────────────────
step "Installing GPU drivers ($GPU)"

if [[ "$GPU" == "nvidia" ]]; then
    sudo pacman -S --needed --noconfirm \
        nvidia-utils lib32-nvidia-utils \
        opencl-nvidia lib32-opencl-nvidia \
        libva-nvidia-driver nvidia-prime \
        nvidia-settings \
        linux-cachyos-nvidia-open
    sudo systemctl enable nvidia-powerd 2>/dev/null || true
    info "NVIDIA drivers installed"

elif [[ "$GPU" == "amd" ]]; then
    sudo pacman -S --needed --noconfirm \
        mesa lib32-mesa \
        vulkan-radeon lib32-vulkan-radeon \
        libva-mesa-driver mesa-vdpau \
        xf86-video-amdgpu \
        vulkan-icd-loader lib32-vulkan-icd-loader
    info "AMD drivers installed"

else
    sudo pacman -S --needed --noconfirm \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        intel-media-driver intel-media-sdk
    info "Intel drivers installed"
fi

# Hybrid Intel iGPU alongside discrete GPU
if [[ "$HYBRID" == "true" ]]; then
    info "Hybrid GPU — adding Intel iGPU packages"
    sudo pacman -S --needed --noconfirm \
        intel-media-driver vulkan-intel lib32-vulkan-intel
fi

# ── Ollama GPU backend ────────────────────────────────────────────────────────
step "Installing Ollama GPU backend"
if [[ "$GPU" == "nvidia" ]]; then
    sudo pacman -S --needed --noconfirm ollama-cuda && info "CUDA backend installed"
elif [[ "$GPU" == "amd" ]]; then
    sudo pacman -S --needed --noconfirm ollama-rocm 2>/dev/null \
        && info "ROCm backend installed" \
        || warn "ollama-rocm not found — Ollama will run CPU-only"
else
    warn "No GPU acceleration for Ollama — CPU only"
fi

# ── AUR packages ──────────────────────────────────────────────────────────────
step "Installing AUR packages"

# Ensure paru is available
if ! command -v paru &>/dev/null; then
    info "Installing paru..."
    git clone https://aur.archlinux.org/paru.git /tmp/paru-build
    (cd /tmp/paru-build && makepkg -si --noconfirm)
fi

AUR_PKGS=(
    apple_cursor
    sddm-astronaut-theme
    sddm-theme-sugar-candy-git
    sddm-nordic-theme-git
    grimblast-git
    pokemon-colorscripts-git
    python-pywalfox
    localsend-bin
    opera-gx

    # Gaming
    spotify
    proton-ge-custom-bin
)

paru -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages failed — check output above"

# ── Open WebUI ────────────────────────────────────────────────────────────────
step "Installing Open WebUI"
pipx install open-webui && info "Open WebUI installed via pipx" \
    || pip install --user open-webui && info "Open WebUI installed via pip"

fi  # end DOTFILES_ONLY==false block

# ── Dotfiles ──────────────────────────────────────────────────────────────────
step "Deploying dotfiles"

mkdir -p ~/.config ~/.local/bin ~/.config/systemd/user

# Config directories — deploy everything in config/ automatically
for dir_path in "$DOTFILES_DIR/config/"/*/; do
    dir_name=$(basename "$dir_path")
    cp -r "$dir_path" ~/.config/
    info "Deployed: ~/.config/$dir_name"
done

# Home files
[[ -f "$DOTFILES_DIR/home/.zshrc_custom" ]] && \
    cp "$DOTFILES_DIR/home/.zshrc_custom" ~/ && info "Deployed: ~/.zshrc_custom"

# Scripts
if [[ -d "$DOTFILES_DIR/home/.local/bin" ]]; then
    cp "$DOTFILES_DIR/home/.local/bin/"* ~/.local/bin/
    chmod +x ~/.local/bin/*
    info "Deployed: ~/.local/bin scripts"
fi

# Open WebUI systemd user service
if [[ -f "$DOTFILES_DIR/home/.config/systemd/user/open-webui.service" ]]; then
    cp "$DOTFILES_DIR/home/.config/systemd/user/open-webui.service" ~/.config/systemd/user/
    # Update ExecStart path for this user
    sed -i "s|/home/luisito|$HOME|g" ~/.config/systemd/user/open-webui.service
    info "Deployed: open-webui.service"
fi

# Add zshrc_custom source to .zshrc if not already there
if ! grep -q "zshrc_custom" ~/.zshrc 2>/dev/null; then
    echo '[[ -f ~/.zshrc_custom ]] && source ~/.zshrc_custom' >> ~/.zshrc
    info "Linked .zshrc_custom in .zshrc"
fi

# ── Jellyfin OSD fix ──────────────────────────────────────────────────────────
step "Installing Jellyfin OSD fix"
if [[ -f "$DOTFILES_DIR/system/jellyfin-osd-fix.sh" ]]; then
    sudo cp "$DOTFILES_DIR/system/jellyfin-osd-fix.sh" /usr/local/bin/
    sudo chmod +x /usr/local/bin/jellyfin-osd-fix.sh
    sudo mkdir -p /etc/pacman.d/hooks
    sudo cp "$DOTFILES_DIR/system/jellyfin-osd-fix.hook" /etc/pacman.d/hooks/
    info "Installed pacman hook → auto-applies fix on every Jellyfin update"
    if [[ -d /usr/share/jellyfin/web ]]; then
        sudo /usr/local/bin/jellyfin-osd-fix.sh
    fi
else
    warn "system/jellyfin-osd-fix.sh not found in dotfiles — skipping"
fi

# ── Desktop-specific adjustments ─────────────────────────────────────────────
if [[ "$IS_LAPTOP" == "false" ]]; then
    step "Desktop machine detected"
    warn "No keyboard backlight — kbd-backlight waybar module will be absent (harmless)"
    warn "No battery — battery-charge-limit service will be skipped"
    warn "eww GPU widgets use nvidia-smi by default — if GPU is AMD, update eww.yuck:"
    warn "  See README.md → 'Porting to a new machine' for AMD eww replacements"
fi

if [[ "$DOTFILES_ONLY" == "true" ]]; then
    step "Manual step required: ml4w"
    echo "  ml4w needs to be installed separately if not already done."
    echo "  Install via: yay -S ml4w-hyprland"
    echo "  Then re-run: cd ~/dotfiles && bash install.sh --dotfiles-only"
    echo ""
    echo -e "${GREEN}  Dotfiles deployed. Done!${NC}"
    exit 0
fi

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
    jellyfin
    ollama
    sddm
    docker
    ufw
    avahi-daemon
    power-profiles-daemon
    switcheroo-control
)
for svc in "${SYSTEM_SVCS[@]}"; do
    sudo systemctl enable "$svc" 2>/dev/null \
        && info "Enabled: $svc" \
        || warn "Could not enable: $svc (may not exist on this hardware)"
done

# NVIDIA power daemon only on NVIDIA
if [[ "$GPU" == "nvidia" ]]; then
    sudo systemctl enable nvidia-powerd 2>/dev/null && info "Enabled: nvidia-powerd"
fi

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
info "UFW enabled (deny incoming, allow SSH)"

# ── Groups ────────────────────────────────────────────────────────────────────
sudo usermod -aG docker "$USER" && info "Added $USER to docker group"
sudo usermod -aG games  "$USER" && info "Added $USER to games group"

# ── Ollama tuning ─────────────────────────────────────────────────────────────
step "Configuring Ollama"
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
Current=Nordic-darker
EOF
info "SDDM theme set to Nordic-darker"

# ── Battery charge limit (laptop only) ───────────────────────────────────────
if [[ "$IS_LAPTOP" == "true" ]]; then
    step "Configuring battery charge limit"
    sudo tee /etc/systemd/system/battery-charge-limit.service > /dev/null <<'EOF'
[Unit]
Description=Set battery charge limit to 80%
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable --now battery-charge-limit 2>/dev/null \
        && info "Battery charge limit set to 80%" \
        || warn "Battery charge limit service failed — may not have BAT0"
else
    info "Desktop detected — skipping battery charge limit service"
fi

# ── Limine bootloader ─────────────────────────────────────────────────────────
step "Configuring Limine"
if [[ -f /boot/limine.conf ]]; then
    sudo sed -i 's/^timeout: .*/timeout: 0/' /boot/limine.conf
    info "Limine timeout set to 0 (instant boot)"
else
    warn "Limine config not found at /boot/limine.conf — skipping"
fi

# ── Ollama models ─────────────────────────────────────────────────────────────
step "Pulling Ollama models"
warn "This will download several GB — make sure you're on a good connection"

# Start ollama if not running
sudo systemctl start ollama 2>/dev/null
sleep 3

ollama pull nomic-embed-text && info "Pulled: nomic-embed-text"
ollama pull llama3.1:8b      && info "Pulled: llama3.1:8b (general)"
ollama pull qwen2.5-coder:7b && info "Pulled: qwen2.5-coder:7b (coding, fast)"

if [[ "$GPU" == "nvidia" ]]; then
    info "NVIDIA detected — pulling 14b model too"
    ollama pull qwen2.5-coder:14b && info "Pulled: qwen2.5-coder:14b (coding, best quality)"
else
    warn "Non-NVIDIA GPU — qwen2.5-coder:14b (9GB) may be slow without CUDA"
    if confirm "Pull qwen2.5-coder:14b anyway?"; then
        ollama pull qwen2.5-coder:14b && info "Pulled: qwen2.5-coder:14b"
    fi
fi

# ── ml4w note ─────────────────────────────────────────────────────────────────
step "Manual step required: ml4w"
echo "  ml4w (the Hyprland dotfiles framework) needs to be installed separately."
echo "  It provides scripts in ~/.config/ml4w/ that the configs depend on."
echo ""
echo "  After reboot, install via CachyOS Package Installer (cachyos-packageinstaller)"
echo "  and search for 'ml4w', or run:"
echo "    yay -S ml4w-hyprland"
echo ""
echo "  Then re-run dotfiles deployment to override ml4w defaults:"
echo "    cd ~/dotfiles && bash install.sh --dotfiles-only"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  All done! Reboot to finish.${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  After reboot:"
echo "  • Open WebUI  → http://localhost:8080"
echo "  • Jellyfin    → http://localhost:8096"
echo "  • Log in and set up Jellyfin media libraries manually"
echo "  • Steam is installed — launch it and log in"
echo "  • Proton-GE is installed — select it in Steam → Settings → Compatibility"
echo ""
echo "  GPU detected: $GPU — drivers installed accordingly"
if [[ "$GPU" == "amd" ]]; then
    echo "  AMD GPU: update eww.yuck GPU widgets (see README → Porting to a new machine)"
fi
echo "  If something looks wrong with graphics, check: sudo dmesg | grep -i drm"
echo ""
