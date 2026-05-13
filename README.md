# LuiNux

My personal Hyprland rice on CachyOS. Luis + Linux = LuiNux.

Built on top of [ml4w](https://github.com/mylinuxforwork/dotfiles) with my own customizations layered on top.

## System
- **OS:** CachyOS (Arch-based)
- **WM:** Hyprland 0.55 (ml4w rice)
- **Bar:** Waybar (ml4w-glass-center theme)
- **Terminal:** Kitty
- **Shell:** Zsh + Oh My Zsh + Oh My Posh (zen theme)
- **Fetch:** Fastfetch with random pokemon sprite
- **Login screen:** SDDM (astronaut theme)
- **Browser:** Zen Browser

## What's in this repo

These are my personal tweaks — not the full rice, just the files I've customized:

| File | What it controls |
|------|-----------------|
| `config/fastfetch/config.jsonc` | Fastfetch layout + pokemon logo |
| `config/hypr/conf/windows/default.conf` | Gaps (5px), borders, layout |
| `config/waybar/modules.json` | Waybar modules, clock (12hr), click-to-reveal drawers |
| `config/waybar/themes/ml4w-glass-center/config` | Waybar margins (flush to top) |
| `config/waybar/themes/ml4w-glass/style.css` | Waybar CSS — Gengar icon, compact pill size |
| `config/kitty/kitty.conf` | Terminal opacity (0.5) + padding |
| `home/.zshrc_custom` | Personal zsh additions |

## Setting up on a new machine

This repo contains customizations only. You still need the base stack first:

**1. Install CachyOS**
https://cachyos.org

**2. Install the ml4w dotfiles**
```
bash <(curl -s https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/setup/install.sh)
```

**3. Install dependencies**
```
paru -S zsh oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting pokemon-colorscripts-git sddm-astronaut-theme zen-browser-bin github-cli
```

**4. Clone this repo and apply files**
```
git clone https://github.com/luisitossb/dotfiles.git ~/dotfiles
cd ~/dotfiles

cp config/fastfetch/config.jsonc ~/.config/fastfetch/
cp config/hypr/conf/windows/default.conf ~/.config/hypr/conf/windows/
cp config/waybar/modules.json ~/.config/waybar/
cp config/waybar/themes/ml4w-glass-center/config ~/.config/waybar/themes/ml4w-glass-center/
cp config/waybar/themes/ml4w-glass/style.css ~/.config/waybar/themes/ml4w-glass/
cp config/kitty/kitty.conf ~/.config/kitty/
cp home/.zshrc_custom ~/.zshrc_custom
```

**5. Set SDDM theme**
```
echo -e "\n[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee -a /etc/sddm.conf
```

**6. Set Zen as default browser**
```
echo "zen-browser" > ~/.config/ml4w/settings/browser.sh
```

## Hardware-specific notes

### AMD GPU (desktop setup)
The eww dashboard GPU widgets are written for NVIDIA and use `nvidia-smi` for GPU temperature and VRAM usage. On an AMD GPU machine these will silently fail or show nothing.

**What needs tweaking in `~/.config/eww/eww.yuck` and `~/.config/eww/eww.scss`:**
- GPU temp: replace `nvidia-smi` call with a read from sysfs, e.g. `cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input` (divide by 1000 for °C) — card number may vary, check with `ls /sys/class/drm/`
- VRAM used/total: replace `nvidia-smi --query-gpu=memory.used` with `rocm-smi --showmeminfo vram` if ROCm is installed, or read from `/sys/class/drm/card1/device/mem_info_vram_used` and `mem_info_vram_total` (values are in bytes)

Everything else in the eww dashboard (CPU, RAM, disk, network, volume, uptime, now-playing) works without any changes.

**No changes needed for:** keyboard backlight module (not applicable on desktop), battery service (not applicable on desktop), all Hyprland/waybar/kitty config.

---

## Keeping dotfiles updated

Run `dotfiles-sync` from anywhere to copy the latest config files and push to GitHub:
```
dotfiles-sync
```

This alias is defined in `home/.zshrc_custom`.
