#!/usr/bin/env bash
# install.sh — Bootstrap a fresh CachyOS install with the LuiNux rice
# Run as your user (NOT root) after a fresh CachyOS base install
#
# Usage:
#   git clone https://github.com/luisitossb/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && bash install.sh
#
# Flags:
#   --dotfiles-only   Skip all package installs; only deploy configs + system files.
#                     Re-deploys dotfiles only, skips package install.
#
# After this script, optionally run:
#   bash scripts/apps/install.sh       — user applications (Discord, Steam, Spotify, etc.)
#   bash scripts/dev/install.sh        — dev tools (Neovim, Node, Python, Rust, etc.)
#   bash scripts/server/install.sh     — self-hosted services (Jellyfin, Sunshine, Docker)
#   bash scripts/server/install-ai.sh  — local AI stack (Ollama + Open WebUI)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}══════ $1 ══════${NC}"; }
info() { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }
trap 'err "install.sh failed at line $LINENO (exit code: $?). Check output above."; exit 1' ERR

# ── Parse flags ───────────────────────────────────────────────────────────────
DOTFILES_ONLY=false
for arg in "$@"; do
    [[ "$arg" == "--dotfiles-only" ]] && DOTFILES_ONLY=true
done

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ "$EUID" -eq 0 ]]; then
    err "Don't run as root. Run as your regular user."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    err "This script is for Arch/CachyOS only."
    exit 1
fi

step "Starting LuiNux setup"
echo "  Dotfiles: $DOTFILES_DIR"
echo "  User:     $USER"
[[ "$DOTFILES_ONLY" == "true" ]] && warn "Dotfiles-only mode — skipping package installs and system config."

# ── Hardware detection ────────────────────────────────────────────────────────
step "Detecting hardware"

GPU="intel"
lspci 2>/dev/null | grep -qi "nvidia"            && GPU="nvidia"
lspci 2>/dev/null | grep -Eqi "amd|radeon"       && GPU="amd"

CPU="intel"
grep -qi "amd" /proc/cpuinfo                     && CPU="amd"

HYBRID=false
lspci 2>/dev/null | grep -Eqi "intel.*(vga|graphics|display)" && [[ "$GPU" != "intel" ]] && HYBRID=true

IS_LAPTOP=false
{ [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; } && IS_LAPTOP=true

info "GPU: $GPU  |  CPU: $CPU  |  Hybrid iGPU: $HYBRID  |  Laptop: $IS_LAPTOP"

# ── System + UI packages ──────────────────────────────────────────────────────
# paru ships with CachyOS — no bootstrap needed
if [[ "$DOTFILES_ONLY" == "false" ]]; then

step "Installing system and UI packages"

SYS_PKGS=(
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
    networkmanager-dmenu-git

    # Bluetooth
    bluez bluez-utils bluez-libs blueman

    # Login manager
    sddm

    # Power / hardware
    power-profiles-daemon upower brightnessctl cpupower
    switcheroo-control

    # Screenshot / clipboard
    cliphist wl-clipboard grim slurp flameshot

    # Theming
    nwg-look nwg-displays qt6ct qt6-virtualkeyboard
    gnome-themes-extra breeze
    matugen

    # System tools
    fastfetch duf pv rsync
    playerctl udiskie ufw inotify-tools
    ripgrep fd bat

    # Widgets / visualizers
    eww cava

    # File managers / media backends
    nautilus dolphin gvfs gvfs-mtp tumbler
    ffmpegthumbnailer loupe
    gst-libav gst-plugin-pipewire gst-plugins-bad gst-plugins-ugly

    # System essentials
    polkit-gnome polkit-kde-agent
    flatpak unrar unzip
    openssh nss-mdns avahi

    # AUR — theming / UI
    apple_cursor
    sddm-astronaut-theme
    sddm-theme-sugar-candy-git
    sddm-nordic-theme-git
    grimblast-git
    pokemon-colorscripts-git
    python-pywalfox
    waypaper
)

paru -S --needed --noconfirm "${SYS_PKGS[@]}" || warn "Some packages failed — check output above"

# ── CPU microcode ─────────────────────────────────────────────────────────────
step "Installing CPU microcode ($CPU)"
if [[ "$CPU" == "intel" ]]; then
    paru -S --needed --noconfirm intel-ucode && info "Intel microcode installed"
else
    paru -S --needed --noconfirm amd-ucode && info "AMD microcode installed"
fi

# ── GPU drivers ───────────────────────────────────────────────────────────────
# chwd auto-selects the correct driver (open vs proprietary NVIDIA, hybrid, etc.)
step "Installing GPU drivers via chwd ($GPU)"
sudo chwd -a pci nonfree 0300 2>/dev/null || sudo chwd -a pci free 0300 2>/dev/null \
    || warn "chwd driver install failed — check: sudo chwd -l"
info "GPU drivers installed via chwd"
[[ "$GPU" == "nvidia" ]] && sudo systemctl enable nvidia-powerd 2>/dev/null || true

fi  # end DOTFILES_ONLY==false block

# ── Dotfiles ──────────────────────────────────────────────────────────────────
step "Deploying dotfiles"

mkdir -p ~/.config ~/.local/bin ~/.config/systemd/user

# Configs we fully own — symlink so edits are immediately tracked in the repo.
# matugen-generated color files (colors.css, colors.conf, colors.rasi) land in
# some of these dirs but are listed in .gitignore so they don't pollute the repo.
SYMLINK_CONFIGS=(
    quickshell   # Quickshell panels — we write all of this
    waybar       # Waybar config + themes (matugen writes colors.css → gitignored)
    kitty        # Terminal config (matugen writes colors.conf → gitignored)
    rofi         # Rofi theme (matugen writes colors.rasi → gitignored)
    btop         # Resource monitor config
    swaync       # Notification daemon config
    fastfetch    # Neofetch replacement config
    ohmyposh     # Shell prompt config
    networkmanager-dmenu  # nm-dmenu config
    Kvantum      # Qt theme engine config
    qt6ct        # Qt6 platform theme config
    cava         # Audio visualizer config + themes
    nwg-look     # GTK appearance settings
    opencode     # AI terminal agent config
)

for name in "${SYMLINK_CONFIGS[@]}"; do
    src="$DOTFILES_DIR/config/$name"
    [[ ! -d "$src" ]] && continue
    # Remove whatever is there (symlink or dir) and create fresh symlink
    rm -rf ~/.config/"$name"
    ln -sf "$src" ~/.config/"$name"
    info "Symlinked: ~/.config/$name"
done

# Configs with machine-specific data written into them — copy rather than symlink
COPY_CONFIGS=(hypr waypaper sunshine eww nwg-dock-hyprland gtk-3.0 gtk-4.0)

for name in "${COPY_CONFIGS[@]}"; do
    src="$DOTFILES_DIR/config/$name"
    [[ ! -d "$src" ]] && continue
    cp -r "$src" ~/.config/
    info "Deployed: ~/.config/$name"
done

# Home files
for f in .zshrc .zshrc_custom .bashrc; do
    [[ -f "$DOTFILES_DIR/home/$f" ]] && cp "$DOTFILES_DIR/home/$f" ~/ && info "Deployed: ~/$f"
done

# Scripts
if [[ -d "$DOTFILES_DIR/home/.local/bin" ]]; then
    cp "$DOTFILES_DIR/home/.local/bin/"* ~/.local/bin/
    chmod +x ~/.local/bin/*
    info "Deployed: ~/.local/bin scripts"
fi

# Systemd user services
if [[ -d "$DOTFILES_DIR/home/.config/systemd/user" ]]; then
    mkdir -p ~/.config/systemd/user
    cp "$DOTFILES_DIR/home/.config/systemd/user/"*.service ~/.config/systemd/user/ 2>/dev/null || true
    systemctl --user daemon-reload
    info "Deployed: systemd user services"
fi

# Fix hardcoded /home/luisito paths (waypaper config)
for f in ~/.config/waypaper/config.ini ~/.config/quickshell/settings/wallpaper-folder; do
    [[ -f "$f" ]] && sed -i "s|/home/luisito|$HOME|g" "$f" && info "Fixed paths in: $f"
done

# GTK dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null && info "GTK dark mode set"
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null \
    || gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true

if [[ "$DOTFILES_ONLY" == "true" ]]; then
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
for svc in NetworkManager bluetooth sddm ufw avahi-daemon power-profiles-daemon switcheroo-control; do
    sudo systemctl enable "$svc" 2>/dev/null \
        && info "Enabled: $svc" \
        || warn "Could not enable: $svc"
done
[[ "$GPU" == "nvidia" ]] && sudo systemctl enable nvidia-powerd 2>/dev/null && info "Enabled: nvidia-powerd"

step "Enabling user services"
systemctl --user daemon-reload
for svc in wireplumber pipewire pipewire-pulse; do
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
sudo usermod -aG games "$USER" 2>/dev/null && info "Added $USER to games group" || warn "games group not found — run again after apps/install.sh"

# ── SDDM theme ────────────────────────────────────────────────────────────────
step "Configuring SDDM"
sudo tee /etc/sddm.conf > /dev/null <<EOF
[Autologin]
Session=hyprland

[Theme]
Current=sddm-astronaut-theme
EOF
info "SDDM theme set to sddm-astronaut-theme"

# Point astronaut theme at the wallpaper cache (auto-updates on wallpaper change)
sudo sed -i 's|Background="Backgrounds/astronaut.png"|Background="Backgrounds/current.png"|' \
    /usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf
mkdir -p "$HOME/.cache/qs-dotfiles"
sudo ln -sf "$HOME/.cache/qs-dotfiles/blurred_wallpaper.png" \
    /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/current.png
# Allow sddm user to traverse the cache path (file itself is already world-readable)
chmod o+x "$HOME" "$HOME/.cache" "$HOME/.cache/qs-dotfiles"
info "SDDM wallpaper symlinked to qs-dotfiles wallpaper cache"

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
    info "Desktop detected — skipping battery charge limit"
fi

# ── Limine bootloader ─────────────────────────────────────────────────────────
step "Configuring Limine"
if [[ -f /boot/limine.conf ]]; then
    sudo sed -i 's/^timeout: .*/timeout: 0/' /boot/limine.conf
    info "Limine timeout set to 0 (instant boot)"
else
    warn "Limine config not found at /boot/limine.conf — skipping"
fi


# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  System setup done! Reboot to finish.${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo "  After reboot, optionally run:"
echo "    bash scripts/apps/install.sh       — Discord, Steam, Spotify, etc."
echo "    bash scripts/dev/install.sh        — Neovim, Node, Python, Rust, etc."
echo "    bash scripts/server/install.sh     — Jellyfin, Sunshine, Docker"
echo "    bash scripts/server/install-ai.sh  — Ollama + Open WebUI"
echo ""
echo "  GPU detected: $GPU — drivers installed via chwd"
[[ "$GPU" == "amd" ]] && echo "  AMD GPU: update eww.yuck GPU widgets (see README → Porting to a new machine)"
echo "  If graphics look wrong: sudo dmesg | grep -i drm"
echo ""
