#!/usr/bin/env bash
# qs-wallpaper.sh — set wallpaper, run matugen, reload UI
# Usage: qs-wallpaper.sh /path/to/image
#        qs-wallpaper.sh --random [folder]

CACHE_DIR="$HOME/.cache/qs-dotfiles"
CACHE_FILE="$CACHE_DIR/current_wallpaper"
BLURRED_WALLPAPER="$CACHE_DIR/blurred_wallpaper.png"
SQUARE_WALLPAPER="$CACHE_DIR/square_wallpaper.png"
RASI_FILE="$CACHE_DIR/current_wallpaper.rasi"
DEFAULT_WALLPAPER="$HOME/dotfiles/wallpapers/Blackhole.jpeg"
BLUR=$(cat "$HOME/.config/quickshell/settings/blur" 2>/dev/null || echo "50x30")
TRANSITION=$(cat "$HOME/.config/quickshell/settings/wallpaper-transition" 2>/dev/null || echo "grow")

# --random: pick a random image from the wallpaper folder
if [[ "$1" == "--random" ]]; then
    FOLDER="${2:-$(cat "$HOME/.config/quickshell/settings/wallpaper-folder" 2>/dev/null || echo "$HOME/dotfiles/wallpapers")}"
    FOLDER="${FOLDER//\$HOME/$HOME}"; FOLDER="${FOLDER//\~/$HOME}"
    IMAGE_PATH=$(find "$FOLDER" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)
    [[ -z "$IMAGE_PATH" ]] && { echo "No images found in $FOLDER" >&2; exit 1; }
else
    IMAGE_PATH="$1"
fi

# Default to last-used wallpaper if no argument
[[ -z "$IMAGE_PATH" ]] && IMAGE_PATH=$(cat "$CACHE_FILE" 2>/dev/null || echo "$DEFAULT_WALLPAPER")

if [[ ! -f "$IMAGE_PATH" ]]; then
    echo "Error: image not found: $IMAGE_PATH" >&2
    exit 1
fi

mkdir -p "$CACHE_DIR"

# Ensure awww-daemon is running
if ! pgrep -x "awww-daemon" > /dev/null; then
    mkdir -p "$HOME/.cache/awww"
    awww-daemon &
    sleep 1
fi

# Save to cache
echo "$IMAGE_PATH" > "$CACHE_FILE"

# Set wallpaper
awww img "$IMAGE_PATH" --transition-type "$TRANSITION"

# Detect dark/light mode — reads explicit setting file, defaults to dark
MATUGEN_MODE=$(cat "$HOME/.config/quickshell/settings/color-mode" 2>/dev/null || echo "dark")

# Run matugen
if [[ -f "$HOME/.cargo/bin/matugen" ]]; then
    "$HOME/.cargo/bin/matugen" image "$IMAGE_PATH" --source-color-index 0 -m "$MATUGEN_MODE"
elif command -v matugen &>/dev/null; then
    matugen image "$IMAGE_PATH" --source-color-index 0 -m "$MATUGEN_MODE"
fi

# Reload Quickshell theme (only if qs is running)
pgrep -x qs > /dev/null && qs ipc call theme-manager reload

# Reload dock
nohup bash -c "$HOME/.config/nwg-dock-hyprland/launch.sh" > /dev/null 2>&1 &

# Refresh swaync
sleep 0.1 && swaync-client -rs

# Create blurred image (for SDDM/rofi)
if command -v magick &>/dev/null; then
    magick "$IMAGE_PATH" -resize 75% "$BLURRED_WALLPAPER"
    [[ "$BLUR" != "0x0" ]] && magick "$BLURRED_WALLPAPER" -blur "$BLUR" "$BLURRED_WALLPAPER"
    magick "$IMAGE_PATH" -gravity Center -extent 1:1 "$SQUARE_WALLPAPER"
    echo "* { current-image: url(\"$BLURRED_WALLPAPER\", height); }" > "$RASI_FILE"
fi
