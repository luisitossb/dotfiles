# Windows → Linux Setup Guide

AI reference document for helping luisito set up CachyOS on the Windows desktop.

---

## The machines

| Machine | Status | OS | Role |
|---------|--------|----|------|
| ASUS laptop (Intel i7-8750H, 32GB RAM, NVIDIA GPU) | Live | CachyOS | Daily driver, source of dotfiles |
| AMD desktop | Target | Windows → CachyOS | Main/gaming PC, getting Linux |
| Mac | Not planned | macOS | install-asahi.sh exists but won't be used — waiting for Framework laptop |

**The desktop is an AMD GPU machine.** This matters for:
- GPU driver section in install.sh (picks AMD branch automatically via lspci)
- eww dashboard GPU widgets (nvidia-smi won't work — needs AMD replacements, see below)
- Ollama will use ROCm if available, CPU-only as fallback

---

## Pre-install checklist (do on Windows before wiping)

- [ ] Back up anything important to the 2TB WD Elements external drive
- [ ] Note the WiFi password (you'll need it fresh install)
- [ ] Download CachyOS ISO: https://cachyos.org/download
- [ ] Write ISO to USB: use Rufus (Windows) or `dd` — use GPT + UEFI mode
- [ ] Disable Secure Boot in BIOS (usually F2/DEL on boot)
- [ ] Set USB as first boot device

**External drive note:** The WD Elements is exFAT (Windows format) and works natively on Linux — no formatting needed. Mount it via Nautilus (Files) or `udisksctl mount -b /dev/sdX1`. Linux reads/writes exFAT fine. If it ever gets corrupted, use `fsck.exfat`.

---

## Installation steps

### 1. Install CachyOS

Boot from USB → choose **CachyOS Desktop** → follow the graphical installer (Calamares).

Partition options:
- **Full wipe (recommended):** Let Calamares use the whole disk — automatic btrfs + subvolumes + swap
- **Dual boot:** If keeping Windows, shrink Windows partition first in Windows Disk Management, then tell Calamares to use the free space

After install, reboot without USB.

### 2. First boot — connect to internet

NetworkManager handles WiFi. Use the nm-applet tray icon or:
```bash
nmcli device wifi connect "YourSSID" password "yourpassword"
```

### 3. Clone dotfiles and run install.sh

```bash
git clone https://github.com/luisitossb/dotfiles.git ~/dotfiles
cd ~/dotfiles && bash install.sh
```

This handles everything: packages, AMD drivers, AUR packages (paru), dotfiles, services, Jellyfin OSD fix, gaming tools (Steam, Proton-GE), firewall. Takes 15-30 minutes depending on connection speed.

### 4. Reboot

### 5. Install ml4w (required — must be done after reboot)

ml4w is the Hyprland dotfiles framework that the configs depend on. Without it, Waybar modules and autostart entries that call `~/.config/ml4w/scripts/` will be broken.

```bash
yay -S ml4w-hyprland
```

Or search "ml4w" in CachyOS Package Installer.

Follow the ml4w installer prompts. It will override some configs.

### 6. Re-deploy dotfiles (overlay on top of ml4w defaults)

```bash
cd ~/dotfiles && bash install.sh --dotfiles-only
```

This skips package installs and re-applies luisito's customizations on top of whatever ml4w set up.

### 7. Set Zen Browser as default

```bash
echo "zen-browser" > ~/.config/ml4w/settings/browser.sh
```

### 8. Fix eww AMD GPU widgets

The eww dashboard calls `nvidia-smi` for VRAM and GPU temp. These return nothing on AMD — widgets show 0. Edit `~/.config/eww/eww.yuck`:

**VRAM widget — replace the `vram_usage` defpoll:**
```
; FROM (NVIDIA):
(defpoll vram_usage :interval "2s" :initial "0"
  `nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk -F', ' '{printf "%.0f", $1/$2*100}'`)

; TO (AMD — sysfs, no tools needed):
(defpoll vram_usage :interval "2s" :initial "0"
  `awk 'BEGIN{u=0;t=0} FILENAME~"used"{u=$1} FILENAME~"total"{t=$1} END{if(t>0)printf "%.0f",u/t*100;else print 0}' /sys/class/drm/card1/device/mem_info_vram_used /sys/class/drm/card1/device/mem_info_vram_total`)
```

**GPU temp widget — replace the `gpu_temp` defpoll:**
```
; FROM (NVIDIA):
(defpoll gpu_temp :interval "2s" :initial "0"
  `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null`)

; TO (AMD — sysfs):
(defpoll gpu_temp :interval "2s" :initial "0"
  `cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input 2>/dev/null | awk '{printf "%.0f", $1/1000}'`)
```

> **Note on `card1` vs `card0`:** On a desktop with one GPU, it's usually `card1`. Verify: `ls /sys/class/drm/` — look for the entry with a `device/mem_info_vram_*` file: `ls /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null`

After editing eww.yuck, restart eww:
```bash
eww kill && eww daemon
```

### 9. Gaming setup

Steam and Proton-GE are already installed by install.sh.

**Enable Proton-GE in Steam:**
Steam → Settings → Compatibility → Enable Steam Play for all titles → select "Proton-GE" from dropdown.

**First Steam launch:** It will download Steam Runtime — takes a few minutes. Then log in.

**Gamemode** is also installed — games that support it will auto-enable it. Manually prefix: `gamemoderun %command%` in Steam launch options.

---

## Post-install: set up Jellyfin

Jellyfin is already installed and running. Add the external drive media:

1. Open http://localhost:8096 in browser
2. Set up admin account on first launch
3. Add libraries pointing to mount path of WD Elements:
   - Find mount path: `lsblk` or check Nautilus sidebar — usually `/run/media/luisito/<drive-name>/`
   - Add Movies, Shows, etc. pointing to the right subfolders
4. The Jellyfin OSD fix (0.5s hide delay) is already applied by install.sh

**If Jellyfin OSD fix needs to be manually verified:**
```bash
grep -o ".\{20\}setTimeout(.,500).\{20\}" /usr/share/jellyfin/web/playback-video.*.chunk.js
```
Should print a line with `setTimeout(...,500)`. If it shows `3e3` instead, run:
```bash
sudo /usr/local/bin/jellyfin-osd-fix.sh
```

---

## What doesn't exist on a desktop (and why it's fine)

| Laptop feature | Desktop impact |
|----------------|---------------|
| Keyboard backlight | `kbd-backlight` Waybar module just won't show — harmless |
| Battery | Battery charge limit service skipped automatically by install.sh |
| Lid close | Hypridle suspend on lid is irrelevant; hypridle still works for screen idle |
| Server/laptop mode toggle | Mode-toggle Waybar module can be removed from modules-right if desired |
| ASUS WMI keyboard backlight scripts | `toggle-kbd-backlight.sh` won't work — ignore it |

---

## Key functions and scripts to know

### `dotfiles-sync` (zsh function in ~/.zshrc_custom)
Copies all configs from ~/.config/ to ~/dotfiles/ and pushes to GitHub. Run from anywhere.
Source: `~/dotfiles/home/.zshrc_custom`

### `install.sh --dotfiles-only`
Re-deploys configs without reinstalling packages. Use after ml4w install or when updating an existing machine's configs from the repo.

### `/usr/local/bin/jellyfin-osd-fix.sh`
Patches the Jellyfin OSD (controls) hide delay from 3s to 0.5s. The pacman hook at `/etc/pacman.d/hooks/jellyfin-osd-fix.hook` runs it automatically on every Jellyfin install/upgrade. No manual intervention needed after updates.

### ml4w scripts at `~/.config/ml4w/scripts/`
Called by Waybar modules and autostart. These are NOT in luisito's dotfiles repo — they come from the ml4w package. Important ones:
- `ml4w-hyprland-settings.sh` — opens the ml4w settings GUI
- `colorscheme-apply.sh` — re-applies matugen color pipeline
- `autostart.sh` — run on Hyprland start

### matugen
Generates Material You color palette from the current wallpaper. Outputs to `~/.config/waybar/colors.css`, `~/.config/eww/colors.scss`, kitty, hyprland, rofi, swaync, btop, ohmyposh, gtk colors. Triggered automatically when wallpaper changes via ml4w.

---

## Troubleshooting

**Waybar not showing:**
```bash
waybar &
# or kill and restart:
pkill waybar; waybar &
```

**eww dashboard not toggling (Super+S):**
```bash
eww kill
eww daemon
```

**Hyprland won't start:**
Check journal: `journalctl -xe | grep hyprland`
Most likely cause: ml4w not installed, or dotfiles deployed before ml4w was set up.

**AMD GPU not detected / black screen:**
Check: `lspci | grep -i vga` and `sudo dmesg | grep -i drm`
CachyOS should auto-detect and install AMD drivers, but if not: `sudo pacman -S mesa vulkan-radeon`

**Networking after install:**
```bash
sudo systemctl enable --now NetworkManager
nmtui  # TUI for connecting to WiFi
```

**Wrong GPU card index for eww (card0 vs card1):**
```bash
ls /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null
```
Use whichever `cardX` has that file.

**Steam won't launch:**
Make sure multilib is enabled in `/etc/pacman.conf` (CachyOS enables it by default).
```bash
sudo pacman -S steam lib32-mesa lib32-vulkan-radeon  # AMD
```

---

## Quick reference commands

```bash
# Mount external drive manually
udisksctl mount -b /dev/sdX1

# Check which GPU driver is loaded
lspci -k | grep -A 3 "VGA"

# Force re-apply matugen colors from current wallpaper
matugen image "$(cat ~/.config/ml4w/settings/wallpaper.sh)"

# Check Jellyfin service status
systemctl status jellyfin

# View Jellyfin logs
journalctl -u jellyfin -f

# Restart Waybar
pkill waybar; waybar &

# Reload Hyprland config without restarting
hyprctl reload
```
