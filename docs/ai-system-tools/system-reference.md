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
- **GPU:** NVIDIA (discrete)
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
- `install-asahi.sh` exists in the repo but won't be used for now

---

## Software stack

### OS / Window Manager
- **OS:** CachyOS (Arch-based, rolling release)
- **AUR helper:** paru
- **Window Manager:** Hyprland 0.55 (deprecation note: .conf format deprecated in favor of Lua in 0.55 — still works, not broken yet)
- **Hyprland framework:** ml4w (separate package, NOT in dotfiles repo — must be installed via `yay -S ml4w-hyprland`)
- **Session manager:** uwsm
- **Login manager:** SDDM (sddm-astronaut-theme)
  - Config: `/etc/sddm.conf` — `[Theme] Current=sddm-astronaut-theme`
  - Theme config: `/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf` — background, colors, blur, font, date/time format
  - **Wallpaper:** Auto-syncs with current ml4w wallpaper — `Backgrounds/current.png` is a symlink to `~/.cache/ml4w/hyprland-dotfiles/blurred_wallpaper.png`. Updates automatically on every wallpaper change, no scripts needed.
  - **Permission setup (one-time):** `chmod o+x ~/ ~/.cache ~/.cache/ml4w ~/.cache/ml4w/hyprland-dotfiles` — allows sddm user to traverse the path to the file (file itself is 644). Already done; included in install.sh.
  - Preview without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme`
  - **Nordic-darker was broken:** requires `org.kde.plasma.*` QML modules (KDE only) — incompatible with a pure Hyprland setup

### Bar / Notifications / Launcher
- **Bar:** Waybar, theme: `ml4w-glass-center`
- **Notifications:** swaync
- **Launcher:** Quickshell LauncherApp (Super+Ctrl+Return) — replaced Rofi drun
- **Screenshot picker:** Quickshell ScreenshotApp (Super+PRINT) — replaced Rofi multi-step flow
- **Clipboard:** cliphist backend + Quickshell ClipboardApp (Super+V) — replaced cliphist-rofi-img.sh
- **Rofi:** Still installed and used for some ml4w scripts; `config-launcher.rasi` is the main theme

### Dock
- **App:** nwg-dock-hyprland, glass theme
- **Config:** `~/.config/nwg-dock-hyprland/` (symlink → ml4w dotfiles)
- **Launch script:** `~/.config/nwg-dock-hyprland/launch.sh` — reads `~/.config/ml4w/settings/dock-theme` (set to `glass`)
- **Icon size:** 32px (`-i 32` flag in launch.sh)
- **Background:** `rgba(18, 20, 14, 0.75)` — matches Kitty terminal background color and opacity exactly
- **Border:** `alpha(@primary, 0.5)` — subtle matugen primary color at 50% opacity
- **Active indicator:** `alpha(@primary, 0.25)` background highlight with 200ms ease transition — auto-matches wallpaper color scheme via matugen. Hover is `alpha(@primary, 0.15)` so active is always visually brighter.
- **Known limitation:** Active window detection can lag slightly — this is nwg-dock-hyprland's IPC event handling, not fixable via CSS or config flags. No "force refresh" signal exists.
- **Transparency note:** Background must be a single `rgba()` layer with no opaque base layer beneath it. The original dual-layer `padding-box` / `border-box` gradient trick blocks compositor transparency. CSS `opacity` on the window element also affects icons — never use it for background-only transparency.
- Restart dock: `~/.config/nwg-dock-hyprland/launch.sh`

### Quickshell widgets
Quickshell is a QML-based Wayland shell toolkit. All interactive panels/overlays run under a single `qs` daemon started by `~/.config/ml4w/scripts/ml4w-autostart`. Toggle any panel via `qs ipc call <target> toggle`.

| Target | Keybind / trigger | What it is |
|--------|-------------------|-----------|
| `dashboard` | **Super+S** | Full stats panel (clock, CPU/RAM/Disk/VRAM, volume, battery, net speed, Claude usage, now-playing) |
| `sidebar` | **Super+Ctrl+S** | ml4w sidebar (volume/brightness sliders, MPRIS, quick toggles, BT/WiFi/Night Mode/DND) |
| `bluetooth-panel` | Click BT Waybar icon | BT device list — paired devices, connect/disconnect, power toggle, scan |
| `wifi-panel` | Click WiFi Waybar icon | WiFi saved networks, connect, radio toggle, "More networks" falls back to nmcli |
| `screenshot` | **Super+PRINT** | Screenshot mode picker: Full/Window/Region/Display → Copy/Save/Copy+Save |
| `clipboard` | **Super+V** | Clipboard history picker — text entries + image thumbnails, search, click to paste |
| `launcher` | **Super+Ctrl+Return** | App launcher — all .desktop apps, icon lookup, search, keyboard navigation |
| `power` | **Super+Ctrl+P** | Power menu |
| `calendar` | **Super+Ctrl+C** | Calendar overlay |
| `sidebar` | top-right "luis" Waybar button | Full sidebar |

**Quick screenshot keybinds (no picker):**
- **Super+Alt+F** → instant full screen copy to clipboard
- **Super+Alt+S** → instant region copy to clipboard (grimblast area)

**Theme colors:** All panels load from `~/.config/ml4w/colors/colors.json` (generated by matugen). `CustomTheme/Theme.qml` reads this on startup. Run `qs ipc call theme-manager reload` after a wallpaper change if colors don't update.

**Helper scripts** (all wrap Python in try/except, always emit valid JSON, errors go to stderr):
- `bt-devices.sh` → JSON array of paired BT devices with connection state
- `wifi-networks.sh` → JSON of saved WiFi networks with active state
- `clipboard-entries.sh` → JSON of cliphist entries; decodes PNG images to `/tmp/qs-clipboard-cache/`
- `app-list.sh` → JSON of all non-hidden .desktop apps with exec, icon paths, terminal flag; sorted by frecency
- `track-usage.sh <name>` → increments launch count in `~/.local/share/qs-launcher/usage.json`

**Error handling:** Every panel (BT, WiFi, Clipboard, Launcher, Dashboard) captures process stderr and shows a dismissible red `ErrorBanner` in the UI when a script fails. Errors are also sent to `console.warn()` which lands in Quickshell's log.

**Troubleshooting commands:**
```bash
qs-log      # view full current Quickshell log (warnings, errors, debug)
qs-errors   # grep only WARN/ERROR lines from the log
```
The log path rotates each qs restart — the aliases find the latest one automatically via `ls -t /run/user/1000/quickshell/by-id/*/log.qslog`.

**Startup:** Quickshell is started automatically by `~/.config/ml4w/scripts/ml4w-autostart` on every Hyprland login — `killall qs && sleep 0.5 && qs &`. No manual steps needed after reboot.

**eww is no longer used** — dashboard migrated to Quickshell. eww daemon was removed from autostart. The scripts in `~/.config/eww/scripts/` (claude-usage.sh, net-speed.sh) are still used by the Quickshell dashboard.

### Terminal / Shell
- **Terminal:** Kitty (opacity 0.75, dynamic opacity, matugen colors)
- **Shell:** Zsh + Oh My Zsh + Oh My Posh (zen theme: `luisito.toml`)
- **Custom aliases/functions:** `~/.zshrc_custom` (sourced from `.zshrc`)

### Browser
- **Primary:** Zen Browser (`zen-browser` AUR package)
- **ml4w default browser setting:** `~/.config/ml4w/settings/browser.sh` — contains `zen-browser`

### File Manager
- **Primary:** Nautilus (GNOME Files)
- **Also installed:** Dolphin (KDE)

### Media / Jellyfin
- **Server:** Jellyfin (system service: `jellyfin.service`)
- **Web UI:** http://localhost:8096
- **Web files location:** `/usr/share/jellyfin/web/`
- **OSD fix:** Applied — reduces controls hide delay from 3s to 0.5s via sed patch on chunk JS file
  - Pacman hook auto-reapplies on every Jellyfin update: `/etc/pacman.d/hooks/jellyfin-osd-fix.hook`
  - Script: `/usr/local/bin/jellyfin-osd-fix.sh`
  - After any Jellyfin update, clear browser cache or test in incognito to confirm fix persisted
  - **Resilience:** Script finds the chunk via `grep -rl "osdHeader-hidden"` (survives filename hash changes), uses flexible regex for minifier variable renames, and fails silently if pattern not found (Jellyfin still works, just reverts to 3s delay)
  - **Break risk:** Low on minor updates. Moderate on major versions if Jellyfin renames `osdHeader-hidden`, changes the 3s timeout value, or refactors the OSD mechanism. Worst case is always safe — fix just doesn't apply.
- **Media library naming:** Standard Jellyfin convention (Movie Name (Year)/Movie Name (Year).mkv)

### Self-hosted Services
- **SearXNG:** Self-hosted private search engine running in Docker. Access at `http://localhost:8888`. Container: `searxng/searxng:latest`, auto-starts with Docker on boot.
- **Docker:** Installed and enabled at boot — used for SearXNG container. Manage with `docker ps -a` / `docker start searxng` / `docker stop searxng`

### Gaming
- **Steam:** Installed (multilib required — enabled by default on CachyOS)
- **Proton-GE:** `proton-ge-custom-bin` (AUR) — use in Steam → Settings → Compatibility
- **Gamemode:** Installed — launch games with `gamemoderun %command%` in Steam options
- **Wine/Winetricks:** Installed for non-Steam Windows apps

### Remote Access (Tailscale + Sunshine + Moonlight)

- **Tailscale:** Installed — creates private WireGuard mesh network between devices. Daemon: `tailscaled.service` (system). Laptop Tailscale IP: run `tailscale ip` to get it
- **Tailscale connected devices:** Linux laptop, Windows desktop, Mac, phone (iOS/Android)
- **Adding a new device:** Install Tailscale + sign in (use auth key method on Mac/iOS — see below), install Moonlight, add PC → use the IP from `tailscale ip`
- **Sunshine:** Installed — self-hosted game stream host (remote desktop server). User service: `sunshine.service`. Web UI: `https://localhost:47990`
- **Moonlight:** Client available on Windows, Mac, iOS, Android — connects to Sunshine via your Tailscale IP (run `tailscale ip`), no port needed
- **Capture config:** `wlr` capture + `vaapi` encoder on `/dev/dri/renderD129` (Intel iGPU). NVENC unusable because Intel drives the display and DMABUF cross-GPU import fails. VAAPI uses Intel's hardware encoder instead.
- **Headless monitor:** `HEADLESS-1` (1920x1080@60) defined in `~/.config/hypr/monitors.conf` — virtual display so Hyprland always has something to render to when lid is closed. Created on each Hyprland start via `exec-once = hyprctl output create headless` in autostart.conf. **Do not run `hyprctl output create headless` manually after boot** — it creates a duplicate `HEADLESS-2` which shows up as an empty workspace 6. Fix if it happens: `hyprctl output remove HEADLESS-2`.
- **DRM layout:** `card1`/`renderD128` = NVIDIA, `card2`/`renderD129` = Intel (eDP-1 laptop screen)
- **No port forwarding needed** — Tailscale handles NAT traversal automatically
- **Moonlight recommended settings:** Video decoder → Hardware, Video codec → HEVC (H.265). Sunshine already encodes HEVC via `hevc_vaapi`. Fall back to H.264 only if a device has compatibility issues.
- **Disconnecting from a session:** Press Ctrl+Alt+Shift+Q on the client device (Windows/Mac/phone) while Moonlight is focused, or Alt+Tab out and close the Moonlight window.

#### Tailscale Mac auth workaround (macOS Sequoia)
macOS Sequoia has a bug where Tailscale never opens the login browser. Bypass it entirely using an auth key:
1. On any already-authenticated device, go to `https://login.tailscale.com/admin/settings/keys` → Generate auth key
2. On the Mac in Terminal run:
```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale login --authkey=tskey-auth-XXXX
```
No browser needed. Works every time.

### AI / Local LLMs
- **Ollama:** Running as system service, max 1 model loaded, 5s keep-alive
- **GPU backend:** ollama-cuda (NVIDIA laptop) / ollama-rocm (AMD desktop, if ROCm works)
- **Models pulled:** nomic-embed-text, llama3.1:8b, qwen2.5-coder:7b (14b removed — too large for VRAM)
- **Open WebUI:** Running as user service at http://localhost:8080 — frontend for Ollama
- **Aliases in zshrc_custom:**
  - `claude` — wrapper function: `command claude --dangerously-skip-permissions --max-turns 20 "$@"` (skip permission prompts, cap turns to prevent runaway loops)
  - `oc` — openclaude with qwen2.5-coder:7b
  - `ai` — aider with qwen2.5-coder:7b

### Theming
- **Theme engine:** matugen (Material You — wallpaper-driven palette)
- **Wallpaper manager:** waypaper (integrated with ml4w)
- **Color pipeline:** wallpaper change → matugen → regenerates color files for waybar, eww, kitty, hyprland, rofi, swaync, btop, ohmyposh, gtk3, gtk4
- **Cursor:** Apple cursor (`apple_cursor` AUR)
- **Icons:** Automatically tied to wallpaper via matugen

---

## Script error handling

All scripts use `set -euo pipefail` + an ERR trap so failures produce a clear error message with line number instead of silently continuing or crashing mid-run.

### Pattern used in install scripts
```bash
err() { echo -e "${RED}  ✗${NC} $1"; }
trap 'err "scriptname.sh failed at line $LINENO (exit code: $?). Check output above."; exit 1' ERR
```

### Pattern used in bin scripts (mode-status, toggle-mode, start-hypridle)
```bash
set -euo pipefail
trap 'echo "[ERROR] scriptname.sh failed at line $LINENO (exit code: $?)" >&2' ERR
```

### Scripts intentionally excluded
- `cliphist-rofi-img.sh` — interactive script; rofi cancellation returns non-zero, which `set -e` would treat as a fatal error. Left as-is.

---

## Key file paths

### Dotfiles repo
```
~/dotfiles/                         — git repo (pushed to github.com/luisitossb/dotfiles)
~/dotfiles/config/                  — config source; most dirs are symlinked from ~/.config/
~/dotfiles/home/                    — home-level files (.zshrc_custom, .local/bin scripts)
~/dotfiles/system/                  — system files requiring sudo (pacman hooks, etc.)
~/dotfiles/docs/ai-system-tools/    — AI reference docs (synced from ~/AI - System Tools/)
~/dotfiles/wallpapers/              — wallpaper collection
~/dotfiles/install.sh               — full CachyOS bootstrap script
~/dotfiles/install-asahi.sh         — Asahi Linux (Apple Silicon) bootstrap script
```

### Config symlink architecture
Most configs are symlinked directly from the repo so edits are immediately tracked in git.
No manual sync needed for symlinked configs — just `git diff` and `git commit`.

**Symlinked → repo** (edit anywhere, git picks it up instantly):
```
~/.config/quickshell  → ~/dotfiles/config/quickshell
~/.config/waybar      → ~/dotfiles/config/waybar
~/.config/kitty       → ~/dotfiles/config/kitty
~/.config/rofi        → ~/dotfiles/config/rofi
~/.config/btop        → ~/dotfiles/config/btop
~/.config/swaync      → ~/dotfiles/config/swaync
~/.config/fastfetch   → ~/dotfiles/config/fastfetch
~/.config/ohmyposh    → ~/dotfiles/config/ohmyposh
~/.config/networkmanager-dmenu → ~/dotfiles/config/networkmanager-dmenu
```

**Copy-deployed** (ml4w or machine-specific data written here — NOT symlinked):
```
~/.config/hypr/       — Hyprland config (ml4w writes environments/default.conf at login)
~/.config/ml4w/       — ml4w framework settings — ml4w fully owns this, not in repo
~/.config/waypaper/   — wallpaper paths updated by ml4w continuously
~/.config/sunshine/   — machine-specific GPU encoder config
```

**ml4w managed** (symlinked to ml4w's internal dotfiles, not the repo):
```
~/.config/nwg-dock-hyprland → ~/.mydotfiles/com.ml4w.dotfiles.stable/.config/nwg-dock-hyprland
~/.config/ml4w             → ~/.mydotfiles/com.ml4w.dotfiles.stable/.config/ml4w
~/.config/waypaper         → ~/.mydotfiles/com.ml4w.dotfiles.stable/.config/waypaper
```

**Gitignored generated files** (matugen writes these on wallpaper change, excluded from repo):
```
~/.config/waybar/colors.css
~/.config/kitty/colors.conf
~/.config/rofi/colors.rasi
```

### Live config locations
```
~/.config/quickshell/scripts/      — bt-devices.sh, wifi-networks.sh, app-list.sh, etc.
~/.config/waybar/themes/ml4w-glass-center/default/style.css — bar styles
~/.config/waybar/modules.json      — all module definitions
~/.config/waybar/colors.css        — auto-generated by matugen (gitignored, do not commit)
~/.config/eww/                     — eww scripts still used by Quickshell dashboard (claude-usage.sh, net-speed.sh)
~/.config/ml4w/settings/browser.sh — contains: zen-browser
~/.config/sunshine/sunshine.conf   — Sunshine capture/encoder config (wlr + vaapi)
~/.zshrc_custom                    — personal zsh additions (sourced by .zshrc)
~/.local/bin/                      — personal scripts
~/.local/share/qs-launcher/usage.json — app launcher frecency data (per-machine, not in repo)
```

### System files (require sudo, not auto-synced to dotfiles)
```
/usr/local/bin/jellyfin-osd-fix.sh     — OSD fix script (tracked in system/ in repo)
/etc/pacman.d/hooks/jellyfin-osd-fix.hook — pacman hook (tracked in system/ in repo)
/etc/systemd/system/ollama.service.d/override.conf — Ollama tuning
/etc/systemd/system/battery-charge-limit.service   — 80% battery cap (laptop only)
/etc/sddm.conf                         — SDDM config (theme + autologin session)
/etc/bluetooth/main.conf               — AutoEnable=false
```

---

## Important commands

### Dotfiles
```bash
dotfiles-sync                       # sync all configs to ~/dotfiles and push to GitHub
cd ~/dotfiles && bash install.sh    # full bootstrap on fresh machine
cd ~/dotfiles && bash install.sh --dotfiles-only  # re-deploy configs only (after ml4w install)
```

### Hyprland
```bash
hyprctl reload                      # reload config without restart
hyprctl clients                     # list open windows
hyprctl monitors                    # list monitors and their properties
hyprctl activewindow               # info on focused window
```

### Waybar
```bash
pkill waybar; waybar &              # kill and restart Waybar
waybar --log-level debug 2>&1 | head -50  # debug launch to see errors
```

### Quickshell
```bash
qs ipc call dashboard toggle        # open/close dashboard (also Super+S)
qs ipc call sidebar toggle          # open/close sidebar
qs ipc call bluetooth-panel toggle  # open/close BT panel
qs ipc call wifi-panel toggle       # open/close WiFi panel
qs ipc call theme-manager reload    # reload colors from colors.json
qs ipc show                         # list all registered IPC targets
pkill qs && qs &                    # restart Quickshell (loads new QML changes)
cat /run/user/1000/quickshell/by-id/*/log.qslog  # view logs / debug errors
```

### Jellyfin
```bash
systemctl status jellyfin           # check if running
sudo systemctl restart jellyfin     # restart server
journalctl -u jellyfin -f          # live logs
sudo /usr/local/bin/jellyfin-osd-fix.sh  # manually apply OSD fix
grep -rl "osdHeader-hidden" /usr/share/jellyfin/web/*.chunk.js  # find the right chunk
```

### Ollama
```bash
ollama list                         # installed models
ollama run qwen2.5-coder:7b         # interactive chat
ollama pull <model>                 # download a model
systemctl status ollama             # service status
journalctl -u ollama -f             # live logs
```

### Remote Access
```bash
tailscale status                        # show connected devices and IPs
tailscale ip                            # show this machine's Tailscale IP
systemctl --user status sunshine        # check Sunshine service
systemctl --user restart sunshine       # restart Sunshine
journalctl --user -u sunshine -f        # live Sunshine logs
hyprctl output create headless          # manually create headless monitor (auto-runs on boot)
# Sunshine web UI: https://localhost:47990
# Sunshine config: ~/.config/sunshine/sunshine.conf
```

### Open WebUI
```bash
systemctl --user status open-webui  # check if running
systemctl --user restart open-webui # restart
journalctl --user -u open-webui -f  # live logs
# Access at: http://localhost:8080
```

### Matugen / theming
```bash
# Force re-apply colors from current wallpaper:
matugen image "$(cat ~/.config/ml4w/settings/wallpaper.sh)"
# Or just change wallpaper via ml4w/waypaper — matugen runs automatically
```

### Swap
```bash
# Swap is zram-based (compressed RAM, NOT SSD — fast, no NVMe wear)
# Managed by: dev-zram0.swap (systemd unit)
sudo systemctl status dev-zram0.swap     # check swap status
# If swap fills up and you want to clear it:
sudo swapoff -a && sudo swapon -a && sudo systemctl start dev-zram0.swap
```

### System / hardware
```bash
lspci | grep -i vga                 # identify GPU
lspci -k | grep -A 3 "VGA"         # GPU + driver in use
sudo dmesg | grep -i drm            # GPU driver messages
ls /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null  # find AMD card index
cat /proc/cpuinfo | grep "model name" | head -1  # CPU model
```

### External drive
```bash
lsblk                               # list block devices (find drive)
udisksctl mount -b /dev/sdX1       # mount external drive
udisksctl unmount -b /dev/sdX1     # unmount safely
# Or just plug in and open Nautilus — auto-mounts
```

### pacman / paru
```bash
sudo pacman -S --needed <pkg>       # install package (--needed skips if already installed)
paru -S <pkg>                       # install AUR package
paru -Syu                           # update everything (pacman + AUR)
sudo pacman -Qs <pkg>               # search installed packages
paru -Ss <pkg>                      # search all packages (pacman + AUR)
sudo pacman -Rns <pkg>              # uninstall + remove orphan deps
```

### Networking
```bash
nmcli device wifi list              # scan WiFi networks
nmcli device wifi connect "SSID" password "pass"  # connect to WiFi
nmcli connection show               # all connections
ip addr                             # show IP addresses
```

---

## Waybar module key details

The bar uses the `ml4w-glass-center` theme. Layout:
- **Left:** App menu (Gengar icon), workspace numbers, new workspace button (`+`)
- **Center:** Network status (WiFi), Bluetooth, clock (12-hour), now-playing
- **Right:** Volume, battery (laptop only), mode toggle, kbd backlight (laptop only), clipboard, hyprshade, power profiles, notifications, exit, ml4w welcome

**Important:** Waybar config at `~/.config/waybar/themes/ml4w-glass-center/config` is NOT a symlink — it's a real file. The dotfiles repo tracks it directly.

**Colors:** Everything uses matugen palette variables (`@primary`, `@secondary`, `@tertiary`, etc.) defined in `~/.config/waybar/colors.css`. The only hardcoded color is the battery critical blink animation (red — intentional).

**Custom modules defined in modules.json:**
- `custom/mode-toggle` — laptop vs server mode (affects hypridle suspend behavior)
- `custom/kbd-backlight` — ASUS keyboard backlight level (0–3), cycles on click
- `custom/nowplaying` — media player info via playerctl
- `custom/appmenu` — Gengar icon launcher button
- `custom/cliphist` — clipboard history picker
- `custom/hyprshade` — screen shader toggle
- `custom/new-workspace` — clickable `+` button, runs `hyprctl dispatch workspace empty` (creates and switches to first empty workspace). Added for Moonlight streaming sessions where Super key is captured by Windows.

**Network module (WiFi click):** Left-click → `qs ipc call wifi-panel toggle` — Quickshell WiFi panel listing saved networks. Click any network to connect. Radio toggle switch at top. "More networks" button falls back to `networkmanager_dmenu` for new/unsaved networks. Right-click still toggles nm-applet.

**Bluetooth module (click):** Left-click → `qs ipc call bluetooth-panel toggle` — Quickshell BT panel. Lists paired devices with connection status (green = connected). Click to connect/disconnect. Power toggle switch at top. "Scan for devices" button runs a 5-second scan then refreshes. Icon: `󰂯` = on/idle, `󰂱` = connected, `󰂲` = off.

---

## ml4w framework — what it provides

ml4w is installed separately (`yay -S ml4w-hyprland`) and lives at `~/.config/ml4w/`. It is NOT tracked in the dotfiles repo. Key things ml4w provides:

- Scripts called by Waybar: network launcher, bluetooth launcher, system update, hyprsunset toggle, wallpaper restore
- `~/.config/ml4w/settings/` — stores user preferences: browser, wallpaper path, color theme
- Autostart listener chain that runs on Hyprland start
- The ml4w welcome app and settings GUI

**Why dotfiles must be re-deployed after ml4w install:** ml4w overwrites some config files with its defaults. Running `install.sh --dotfiles-only` re-applies luisito's customizations on top.

---

## Pacman hooks

Hooks in `/etc/pacman.d/hooks/` run automatically on package operations:

| Hook file | Trigger | What it does |
|-----------|---------|-------------|
| `jellyfin-osd-fix.hook` | jellyfin install/upgrade | Patches OSD timeout from 3s to 0.5s, restarts Jellyfin |

CachyOS also installs its own hooks via `cachyos-hooks` package.

---

## Things that were tried and removed

| Feature | What happened | Notes |
|---------|--------------|-------|
| System tray in Waybar | Added, then removed | Works (`tray` module) but couldn't get it in its own separate bubble without a second Waybar instance; removed for now |
| Zen Browser in autostart | Removed | Annoying to have it auto-open on login |
| Discord in autostart | Removed | Same reason |
| Super+Alt+W wallpaper keybind | Removed | Not useful in practice |
| Jellyfin CSS OSD override | Tried, didn't work | Custom CSS in Jellyfin branding/admin affects only styling, can't override JS-driven class toggling |
| Session save/restore scripts | Removed | Caused eww widget duplication on reboot |
| Quick-search terminal (Super+\\) | Removed | Caused Hyprland windowrule errors |
| Scroll speed overrides (Opera/Discord) | Removed | Broke Opera settings menu |
| localsearch-3 (GNOME Tracker) | Masked | File indexer for GNOME search — not needed on Hyprland, was throwing constant D-Bus errors. Masked via `systemctl --user mask localsearch-3`. Tracked in dotfiles so mask persists on reinstall. |
| Sunshine windowrule (hide workspace 6) | Removed | `windowrule = workspace special:sunshine silent, class:^(sunshine)$` caused Hyprland config errors — invalid field class syntax. Workspace 6 stays visible when Moonlight is connected, acceptable tradeoff. |
| linux-cachyos-nvidia-open | Wrong package | Open NVIDIA kernel module only supports Turing (RTX 20xx+). GTX 1060 (Pascal) requires `linux-cachyos-nvidia` (proprietary). install.sh now uses `chwd` which auto-selects the correct driver. |

---

## dotfiles-sync function explained

Defined in `~/.zshrc_custom`. Run it with: `dotfiles-sync`

What it does:
1. `cd ~/dotfiles`
2. rsync each config directory from `~/.config/` into `dotfiles/config/`
3. Copies `~/.zshrc_custom` to `dotfiles/home/`
4. rsync `~/.local/bin/*.sh` scripts (skips non-script binaries)
5. rsync `~/.config/systemd/user/` (skips `default.target.wants/`)
6. rsync `~/AI\ -\ System\ Tools/*.md` into `dotfiles/docs/ai-system-tools/` (with --delete, so deletions sync too)
7. `git add . && git commit -m "sync: YYYY-MM-DD HH:MM" && git push`

The `AI - System Tools/` directory on the laptop contains markdown files documenting various fixes and setups. These get pushed to the repo as `docs/ai-system-tools/` so they're accessible from anywhere and AI assistants can reference them.

**Important:** Files created directly in `~/dotfiles/docs/ai-system-tools/` will be deleted on the next sync if they don't also exist in `~/AI - System Tools/`. Always create new docs in `~/AI - System Tools/` first.
