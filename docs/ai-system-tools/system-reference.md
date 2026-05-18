# LuiNux — System Reference

Full reference document for AI assistants. Read this to understand the system without needing to ask the user for context.

---

## Who is the user

- **Name:** Luisito (luisito on GitHub: luisitossb)
- **Skill level:** Comfortable with Linux, follows explanations well, prefers things done for them rather than step-by-step manual instructions
- **Preferences:** Concise responses, no unnecessary commentary, verify from docs/sources before guessing, list sudo commands before running them

---

## Hardware inventory

### Laptop (current daily driver — CachyOS)
- **Model:** ASUS laptop
- **CPU:** Intel i7-8750H
- **RAM:** 32GB
- **GPU:** NVIDIA (discrete) + Intel iGPU (hybrid — Intel drives the display)
- **Storage:** 1TB NVMe (btrfs with snapshots via snapper)
- **Form factor:** Laptop — has keyboard backlight (`asus::kbd_backlight`), battery (`BAT0`), lid

### Desktop (Windows → CachyOS migration target)
- **GPU:** AMD discrete GPU
- **Form factor:** Desktop — no keyboard backlight, no battery, no lid
- **Status:** Currently runs Windows; plan is to install CachyOS

### External storage
- **Device:** 2TB WD Elements Portable
- **Format:** exFAT (works natively on Linux — no reformatting needed)
- **Mount path on Linux:** `/run/media/luisito/<drive-label>/` (auto-mounted via udisks2/Nautilus)
- **Use:** Media storage (movies, shows) for Jellyfin

### Mac (not being migrated)
- Waiting for a Framework laptop to replace it instead

---

## Software stack

### OS / Window Manager
- **OS:** CachyOS (Arch-based, rolling release)
- **AUR helper:** paru
- **Window Manager:** Hyprland (uwsm session)
- **Framework:** None — fully standalone dotfiles, no ml4w
- **Session manager:** uwsm
- **Login manager:** SDDM (sddm-astronaut-theme)
  - Config: `/etc/sddm.conf` — `[Theme] Current=sddm-astronaut-theme`
  - **Wallpaper:** `Backgrounds/current.png` symlinks to `~/.cache/qs-dotfiles/blurred_wallpaper.png`. Updates automatically on wallpaper change.
  - **Permission setup (one-time):** `chmod o+x ~/ ~/.cache ~/.cache/qs-dotfiles` — allows sddm user to traverse to the file. Already done in install.sh.

### Bar / Notifications / Launcher
- **Bar:** Waybar, theme: `glass-center` (`~/.config/waybar/themes/glass-center/`)
- **Notifications:** swaync
- **Launcher:** Quickshell LauncherApp (Super+Ctrl+Return)
- **Screenshot:** flameshot (Super+Shift+S) — freeze frame, select region, copy to clipboard. Quickshell ScreenshotApp available via `qs ipc call screenshot toggle` (no keybind)
- **Clipboard:** cliphist backend + Quickshell ClipboardApp — accessible via `qs ipc call clipboard toggle` (no keybind)
- **Rofi:** Still installed (used as fallback/secondary launcher)

### Dock
- **App:** nwg-dock-hyprland, glass theme
- **Config:** `~/.config/nwg-dock-hyprland/` (copy-deployed from dotfiles — NOT symlinked)
- **Launch script:** `~/.config/nwg-dock-hyprland/launch.sh`
- **Icon size:** 32px (`-i 32` flag in launch.sh)

### Quickshell widgets
Quickshell is a QML-based Wayland shell toolkit. All panels run under a single `qs` daemon started by `~/.config/quickshell/scripts/qs-autostart.sh`. Toggle any panel via `qs ipc call <target> toggle`.

| Target | Keybind / trigger | What it is |
|--------|-------------------|-----------|
| `dashboard` | **Super+S** | Full stats panel (clock, CPU/RAM/Disk/VRAM, volume, battery, net speed, now-playing) |
| `sidebar` | Click **"luis"** (top-right Waybar) | Widget center (volume/brightness sliders, MPRIS, connectivity toggles, UI toggles, launch buttons) |
| `bluetooth-panel` | Click BT Waybar icon | BT device list — paired devices, connect/disconnect, power toggle, scan |
| `wifi-panel` | Click WiFi Waybar icon | WiFi saved networks, connect, radio toggle |
| `screenshot` | *(no keybind)* | Screenshot mode picker: Full/Window/Region/Display → Copy/Save/Copy+Save |
| `clipboard` | *(no keybind)* | Clipboard history picker — text entries + image thumbnails, search, click to paste |
| `launcher` | **Super+Ctrl+Return** | App launcher — all .desktop apps, icon lookup, search, keyboard navigation |
| `wallpaper` | **Super+Ctrl+W** | Wallpaper picker — image grid from wallpaper folder, search, click to apply |

**Widget center (sidebar) contents:**
- Volume slider, brightness slider
- Mouse scroll speed slider + number input (writes to `input.scroll_factor` in keyboard.conf)
- Mouse sensitivity slider + number input (writes to `device[2.4g-mouse-1].sensitivity`)
- Trackpad scroll speed slider + number input (writes to `input.touchpad.scroll_factor`)
- Trackpad sensitivity slider + number input (writes to `device[elan1200:00-04f3:307a-touchpad].sensitivity`)
- MPRIS media player (shows when media is playing)
- Connectivity toggles: Bluetooth, WiFi, Night Mode (hyprsunset -t 4000), Do Not Disturb
- UI toggles: Waybar, Dock, Gamemode, Fastfetch
- Launch buttons: Wallpaper picker, Theme picker
- Helper script: `~/.local/bin/set-scroll.sh [mouse|trackpad] [scroll|sens] VALUE`

**Theme colors:** All panels load from `~/.config/quickshell/colors/colors.json` (generated by matugen). `CustomTheme/Theme.qml` reads this on startup.

**Helper scripts** (in `~/.config/quickshell/scripts/`):
- `bt-devices.sh` → JSON array of paired BT devices with connection state
- `wifi-networks.sh` → JSON of saved WiFi networks with active state
- `clipboard-entries.sh` → JSON of cliphist entries; decodes PNG images to `/tmp/qs-clipboard-cache/`
- `app-list.sh` → JSON of all non-hidden .desktop apps with exec, icon paths, terminal flag; sorted by frecency
- `track-usage.sh <name>` → increments launch count in `~/.local/share/qs-launcher/usage.json`
- `qs-wallpaper.sh` → sets wallpaper, runs matugen, updates blurred/square cache images
- `qs-themes.sh` → theme picker

**Startup:** `qs-autostart.sh` is called by Hyprland's `exec-once` on every login.

**Troubleshooting:**
```bash
qs-log      # view full current Quickshell log
qs-errors   # grep only WARN/ERROR lines
```

### Terminal / Shell
- **Terminal:** Kitty (opacity 0.75, dynamic opacity, matugen colors)
- **Shell:** Zsh + Oh My Zsh + Oh My Posh (zen theme: `~/.config/ohmyposh/luisito.toml`)
- **Shell files:**
  - `~/.zshrc` — main shell config (in dotfiles repo, copy-deployed)
  - `~/.zshrc_custom` — personal aliases/functions (in dotfiles repo, copy-deployed)
- **Custom aliases in zshrc_custom:**
  - `claude` — `command claude --dangerously-skip-permissions --max-turns 20 "$@"`
  - `dotfiles-sync` — sync configs to repo and push

### Browser
- **Primary:** Zen Browser (`zen-browser` AUR package)

### File Managers
- **Primary:** Nautilus (GNOME Files) — default for `inode/directory`. Themes automatically via GTK/matugen.
- **Also installed:** Dolphin (KDE) — theming outside KDE Plasma is not reliable. kded6 (from plasma-integration) resets colors after a few seconds. Leave as-is.

### Qt theming
- **Engine:** Kvantum → KvRoughGlass theme (glass/dark aesthetic)
- **Platform theme:** qt6ct (`QT_QPA_PLATFORMTHEME=qt6ct` env var)
- **Configs:** `~/.config/Kvantum/` and `~/.config/qt6ct/` (symlinked from dotfiles)
- **Matugen integration:** `~/.config/qt6ct/colors/matugen.conf` is auto-generated on wallpaper change via `~/.config/matugen/templates/qt6ct-colors.conf`
- **kdeglobals:** `~/.config/kdeglobals` is auto-generated on wallpaper change via `~/.local/bin/gen-kdeglobals.sh` (post-hook on colorsjson template). Used by KDE apps.
- **plasma-integration:** Installed (provides `KDEPlasmaPlatformTheme6.so`) — not active (env var stays qt6ct). Installed as Dolphin theming experiment.

### GTK theming
- **Dark mode:** `gsettings org.gnome.desktop.interface color-scheme prefer-dark`
- **GTK3 theme:** adw-gtk3-dark
- **Settings files:** `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` (copy-deployed from dotfiles)
- **Icon theme:** kora
- **Cursor:** macOS (at `/usr/share/icons/macOS/`) — set via `cursor.conf` and gsettings

### Media / Jellyfin
- **Server:** Jellyfin (system service: `jellyfin.service`)
- **Web UI:** http://localhost:8096
- **OSD fix:** Applied — reduces controls hide delay from 3s to 0.5s via sed patch on chunk JS file
  - Pacman hook auto-reapplies on every Jellyfin update: `/etc/pacman.d/hooks/jellyfin-osd-fix.hook`
  - Script: `/usr/local/bin/jellyfin-osd-fix.sh`
- **Media library naming:** Standard Jellyfin convention (Movie Name (Year)/Movie Name (Year).mkv)

### Self-hosted Services
- **SearXNG:** Self-hosted private search engine running in Docker. Access at `http://localhost:8888`. Container: `searxng/searxng:latest`, auto-starts with Docker on boot.
- **Docker:** Installed and enabled at boot. Manage with `docker ps -a` / `docker start searxng` / `docker stop searxng`

### Gaming
- **Steam:** Installed (multilib required — enabled by default on CachyOS)
- **Proton-GE:** `proton-ge-custom-bin` (AUR) — use in Steam → Settings → Compatibility
- **Gamemode:** Installed — launch games with `gamemoderun %command%` in Steam options
- **Wine/Winetricks:** Installed for non-Steam Windows apps

### Remote Access (Tailscale + Sunshine + Moonlight)
- **Tailscale:** Installed — creates private WireGuard mesh network. Daemon: `tailscaled.service`
- **Sunshine:** Installed — self-hosted game stream host. User service: `sunshine.service`. Web UI: `https://localhost:47990`
- **Moonlight:** Client on Windows, Mac, iOS, Android — connects via Tailscale IP
- **Capture config:** `wlr` capture + `vaapi` encoder on `/dev/dri/renderD129` (Intel iGPU). NVENC unusable because Intel drives the display.
- **Headless monitor:** `HEADLESS-1` (1920x1080@60) — virtual display so Hyprland renders when lid closed. Created via `exec-once = hyprctl output create headless`.
- **DRM layout:** `card1`/`renderD128` = NVIDIA, `card2`/`renderD129` = Intel (eDP-1 laptop screen)

#### Tailscale Mac auth workaround (macOS Sequoia)
```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale login --authkey=tskey-auth-XXXX
```

### AI / Local LLMs
- **Ollama:** Running as system service, max 1 model loaded, 5s keep-alive
- **GPU backend:** ollama-cuda (NVIDIA laptop)
- **Open WebUI:** Running as user service at http://localhost:8080

### Theming
- **Theme engine:** matugen (Material You — wallpaper-driven palette)
- **Wallpaper manager:** Quickshell WallpaperApp (Super+Ctrl+W) + waypaper (CLI)
- **Color pipeline:** wallpaper change → `qs-wallpaper.sh` → matugen → regenerates colors for waybar, kitty, rofi, swaync, quickshell, hyprland, btop, ohmyposh, gtk3/gtk4
- **Cursor:** macOS cursor theme (`/usr/share/icons/macOS/`) — set in `cursor.conf` and GTK settings
- **Icons:** kora icon theme

---

## Key file paths

### Ricing Hub (everything ricing-related)
```
~/Ricing Hub/
  dotfiles/          — git repo (github.com/luisitossb/dotfiles)
  AI - System Tools/ — AI reference docs (this file lives here)
  Config Hub/        — shortcuts, keybindings reference
```

### Dotfiles repo structure
```
~/Ricing Hub/dotfiles/
  config/            — config source (most symlinked to ~/.config/)
  home/              — home-level files (.zshrc, .zshrc_custom, .bashrc, .local/bin/)
  system/            — system files requiring sudo (pacman hooks, etc.)
  docs/              — pushed copy of AI - System Tools/ docs
  wallpapers/        — wallpaper collection
  install.sh         — full CachyOS bootstrap script
  scripts/           — optional install scripts (apps, dev, server, ai)
```

### Config symlink architecture

**Symlinked → repo** (edit anywhere, git picks it up instantly):
```
~/.config/quickshell        → ~/Ricing Hub/dotfiles/config/quickshell
~/.config/waybar            → ~/Ricing Hub/dotfiles/config/waybar
~/.config/kitty             → ~/Ricing Hub/dotfiles/config/kitty
~/.config/rofi              → ~/Ricing Hub/dotfiles/config/rofi
~/.config/btop              → ~/Ricing Hub/dotfiles/config/btop
~/.config/swaync            → ~/Ricing Hub/dotfiles/config/swaync
~/.config/fastfetch         → ~/Ricing Hub/dotfiles/config/fastfetch
~/.config/ohmyposh          → ~/Ricing Hub/dotfiles/config/ohmyposh
~/.config/networkmanager-dmenu → ~/Ricing Hub/dotfiles/config/networkmanager-dmenu
~/.config/Kvantum           → ~/Ricing Hub/dotfiles/config/Kvantum
~/.config/qt6ct             → ~/Ricing Hub/dotfiles/config/qt6ct
~/.config/cava              → ~/Ricing Hub/dotfiles/config/cava
~/.config/nwg-look          → ~/Ricing Hub/dotfiles/config/nwg-look
```

**Copy-deployed** (machine-specific or generated data written here — NOT symlinked):
```
~/.config/hypr/         — Hyprland config (machine-specific overrides written here)
~/.config/waypaper/     — wallpaper path config
~/.config/nwg-dock-hyprland/ — dock config
~/.config/eww/          — eww (scripts still used by dashboard)
~/.config/gtk-3.0/      — GTK3 settings (cursor, theme, icons)
~/.config/gtk-4.0/      — GTK4 settings
~/.config/sunshine/     — machine-specific GPU encoder config
```

**Gitignored generated files** (matugen writes on wallpaper change):
```
~/.config/waybar/colors.css
~/.config/kitty/colors.conf
~/.config/rofi/colors.rasi
~/.config/quickshell/colors/colors.css
~/.config/hypr/colors.conf
```

### Live config locations
```
~/.config/quickshell/scripts/      — bt-devices.sh, wifi-networks.sh, app-list.sh, qs-wallpaper.sh, etc.
~/.config/waybar/themes/glass-center/  — waybar theme (config + style.css)
~/.config/waybar/modules.json      — all waybar module definitions
~/.config/quickshell/settings/     — wallpaper-folder, state flags
~/.config/quickshell/state/        — runtime state flags (waybar-disabled, dock-disabled, etc.)
~/.config/hypr/conf/               — hyprland config fragments (keybindings, autostart, cursor, etc.)
~/.config/sunshine/sunshine.conf   — Sunshine capture/encoder config
~/.zshrc                           — main zsh config
~/.zshrc_custom                    — personal aliases/functions
~/.local/bin/                      — personal scripts
~/.local/share/qs-launcher/usage.json — app launcher frecency data (per-machine, not in repo)
```

### System files (require sudo)
```
/etc/pacman.d/hooks/jellyfin-osd-fix.hook  — pacman hook
/usr/local/bin/jellyfin-osd-fix.sh         — OSD fix script
/etc/systemd/system/battery-charge-limit.service — 80% battery cap (laptop only)
/etc/sddm.conf                             — SDDM config
/etc/bluetooth/main.conf                   — AutoEnable=false
```

---

## Important commands

### Dotfiles
```bash
dotfiles-sync                                        # sync configs to repo and push
cd ~/Ricing\ Hub/dotfiles && bash install.sh         # full bootstrap on fresh machine
cd ~/Ricing\ Hub/dotfiles && bash install.sh --dotfiles-only  # re-deploy configs only
```

### Hyprland
```bash
hyprctl reload                  # reload config without restart
hyprctl clients                 # list open windows
hyprctl monitors                # list monitors and their properties
hyprctl activewindow            # info on focused window
```

### Waybar
```bash
~/.config/waybar/launch.sh      # restart Waybar (handles locking + env setup)
waybar --log-level debug 2>&1 | head -50  # debug launch
```

### Quickshell
```bash
qs ipc call sidebar toggle          # open/close widget center
qs ipc call dashboard toggle        # open/close dashboard (Super+S)
qs ipc call bluetooth-panel toggle  # open/close BT panel
qs ipc call wifi-panel toggle       # open/close WiFi panel
qs ipc call wallpaper toggle        # open/close wallpaper picker
qs ipc show                         # list all registered IPC targets
pkill -x qs && bash ~/.config/quickshell/scripts/qs-autostart.sh &  # restart Quickshell
cat /run/user/1000/quickshell/by-id/*/log.qslog  # view logs
```

### Jellyfin
```bash
systemctl status jellyfin           # check if running
sudo systemctl restart jellyfin     # restart server
journalctl -u jellyfin -f          # live logs
sudo /usr/local/bin/jellyfin-osd-fix.sh  # manually apply OSD fix
```

### Ollama
```bash
ollama list                         # installed models
ollama run qwen2.5-coder:7b         # interactive chat
ollama pull <model>                 # download a model
systemctl status ollama             # service status
```

### Remote Access
```bash
tailscale status                    # show connected devices and IPs
tailscale ip                        # show this machine's Tailscale IP
systemctl --user status sunshine    # check Sunshine service
systemctl --user restart sunshine   # restart Sunshine
journalctl --user -u sunshine -f   # live Sunshine logs
hyprctl output create headless      # manually create headless monitor (auto-runs on boot)
```

### Open WebUI
```bash
systemctl --user status open-webui  # check if running
systemctl --user restart open-webui # restart
# Access at: http://localhost:8080
```

### Matugen / theming
```bash
# Force re-apply colors from current wallpaper:
~/.config/quickshell/scripts/qs-wallpaper.sh "$(cat ~/.cache/qs-dotfiles/current_wallpaper)"
# Or change wallpaper via Super+Ctrl+W — matugen runs automatically
```

### Swap
```bash
# Swap is zram-based (compressed RAM, NOT SSD — fast, no NVMe wear)
sudo systemctl status dev-zram0.swap
sudo swapoff -a && sudo swapon -a && sudo systemctl start dev-zram0.swap
```

### System / hardware
```bash
lspci | grep -i vga                 # identify GPU
lspci -k | grep -A 3 "VGA"         # GPU + driver in use
sudo dmesg | grep -i drm            # GPU driver messages
cat /proc/cpuinfo | grep "model name" | head -1  # CPU model
```

### pacman / paru
```bash
sudo pacman -S --needed <pkg>       # install package
paru -S <pkg>                       # install AUR package
paru -Syu                           # update everything
sudo pacman -Rns <pkg>              # uninstall + remove orphan deps
```

---

## Waybar module key details

The bar uses the `glass-center` theme. Layout:
- **Left:** App menu icon, workspace numbers, new workspace button (`+`)
- **Center:** Network status (WiFi), Bluetooth, clock (12-hour), now-playing
- **Right:** Volume, battery (laptop only), mode toggle, power profiles, sidebar button

**Bluetooth module:** Icon states: `󰊯` = on/idle, `󰊳` = connected, `󰊲` = off, `󰂲` = disabled/rfkill.
Click → `qs ipc call bluetooth-panel toggle`

**Bluetooth note:** After reboot, if bluetooth was powered off in a previous session, rfkill soft-blocks it and Waybar shows `󰂲`. Use the Bluetooth toggle in the widget center or `rfkill unblock bluetooth` to restore.

**Network module:** Click → `qs ipc call wifi-panel toggle`

---

## Pacman hooks

| Hook file | Trigger | What it does |
|-----------|---------|-------------|
| `jellyfin-osd-fix.hook` | jellyfin install/upgrade | Patches OSD timeout from 3s to 0.5s, restarts Jellyfin |

---

## Things that were tried and removed

| Feature | What happened | Notes |
|---------|--------------|-------|
| ml4w framework | Fully removed | Replaced with standalone dotfiles. All ml4w scripts/configs purged. |
| Power buttons in widget center | Removed | User prefers hardware power button |
| System tray in Waybar | Removed | Works (`tray` module) but couldn't isolate in its own bubble |
| Zen Browser in autostart | Removed | Annoying to have auto-open on login |
| Discord in autostart | Removed | Same reason |
| Super+Alt+W wallpaper keybind | Removed | Not useful in practice |
| Jellyfin CSS OSD override | Tried, didn't work | Custom CSS can't override JS-driven class toggling |
| Session save/restore scripts | Removed | Caused eww widget duplication on reboot |
| Quick-search terminal (Super+\\) | Removed | Caused Hyprland windowrule errors |
| localsearch-3 (GNOME Tracker) | Masked | File indexer not needed on Hyprland, was throwing D-Bus errors |
| linux-cachyos-nvidia-open | Wrong package | Open NVIDIA module only supports Turing (RTX 20xx+). GTX 1060 requires `linux-cachyos-nvidia`. install.sh uses `chwd` which auto-selects. |
| apple_cursor AUR package | Not installed | cursor.conf switched to `macOS` theme which is installed at `/usr/share/icons/macOS/` |

---

## dotfiles-sync function

Defined in `~/.zshrc_custom`. Run with: `dotfiles-sync`

What it does:
1. `cd ~/Ricing\ Hub/dotfiles`
2. Copies home files (`.zshrc`, `.zshrc_custom`) to `home/`
3. rsync `~/.local/bin/` scripts
4. rsync `~/Ricing\ Hub/AI\ -\ System\ Tools/*.md` into `docs/ai-system-tools/` (with --delete)
5. `git add . && git commit -m "sync: YYYY-MM-DD HH:MM" && git push`

**Note:** Symlinked configs (quickshell, waybar, kitty, etc.) are tracked automatically — edits there are already in the repo. Copy-deployed configs (hypr, nwg-dock-hyprland, gtk-3.0/4.0) need manual sync if changed.
