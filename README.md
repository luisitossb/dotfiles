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

## Hardware reference

### Source machine (current laptop)
- **Model:** ASUS laptop
- **CPU:** Intel i7-8750H
- **RAM:** 32GB
- **GPU:** NVIDIA (discrete)
- **Storage:** 1TB NVMe (btrfs)
- **Form factor:** Laptop — has keyboard backlight (asus::kbd_backlight), battery, lid

### Target machine (AMD desktop)
- **GPU:** AMD (discrete)
- **Form factor:** Desktop — no keyboard backlight, no battery, no lid

---

## Porting to a new machine

### What transfers with zero changes
Everything visual and behavioral works on any machine:
- All Hyprland config (gaps, borders, keybindings, windowrules, autostart)
- Waybar (layout, modules, Gengar icon, drawers, mode toggle, 12hr clock)
- eww dashboard — CPU, RAM, disk, network speed, volume, uptime, now-playing
- Kitty, Zsh, Fastfetch, SDDM theme, Zen Browser

### What needs changes on an AMD desktop

**eww GPU widgets — file: `~/.config/eww/eww.yuck`**

There are two `defpoll` blocks that call `nvidia-smi`. On AMD these return nothing and the widgets show 0.

**`vram_usage` poll (VRAM % used):**
```
; CURRENT (NVIDIA):
(defpoll vram_usage :interval "2s" :initial "0"
  `nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk -F', ' '{printf "%.0f", $1/$2*100}'`)

; REPLACE WITH (AMD — sysfs, no extra tools needed):
(defpoll vram_usage :interval "2s" :initial "0"
  `awk 'BEGIN{u=0;t=0} FILENAME~"used"{u=$1} FILENAME~"total"{t=$1} END{if(t>0)printf "%.0f",u/t*100;else print 0}' /sys/class/drm/card1/device/mem_info_vram_used /sys/class/drm/card1/device/mem_info_vram_total`)
```

**`gpu_temp` poll (GPU temperature):**
```
; CURRENT (NVIDIA):
(defpoll gpu_temp :interval "2s" :initial "0"
  `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null`)

; REPLACE WITH (AMD — sysfs, no extra tools needed):
(defpoll gpu_temp :interval "2s" :initial "0"
  `cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | awk '{printf "%.0f", $1/1000}'`)
```

> **Note:** `card1` is typical for a desktop with one GPU but verify first: `ls /sys/class/drm/` — look for `card0` or `card1` that has a `device/` subdirectory with `mem_info_vram_*` files.

### What's irrelevant on a desktop (skip or remove)
- **Keyboard backlight** — waybar `kbd-backlight` module and scripts (`~/.local/bin/kbd-backlight-status.sh`, `toggle-kbd-backlight.sh`) — desktop has no backlight, module will just be absent from bar
- **Battery service** — `/etc/systemd/system/battery-charge-limit.service` — no battery on desktop, skip entirely
- **Hypridle suspend** — `~/.config/hypr/hypridle.conf` has a 1800s suspend listener — fine to keep but won't do much on a desktop that's always on
- **Server/laptop mode toggle** — lid-close behavior toggle is irrelevant without a lid; the mode-toggle waybar module can be removed from `modules.json` if desired

---

## Keeping dotfiles updated

Run `dotfiles-sync` from anywhere to copy the latest config files and push to GitHub:
```
dotfiles-sync
```

This alias is defined in `home/.zshrc_custom`.
