#!/bin/bash
set -euo pipefail
trap 'echo "[ERROR] toggle-mode.sh failed at line $LINENO (exit code: $?)" >&2' ERR
STATE_FILE="$HOME/.config/mode/current"
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop")

if [ "$MODE" = "laptop" ]; then
    NEW_MODE="server"
    LID_ACTION="ignore"
else
    NEW_MODE="laptop"
    LID_ACTION="suspend"
fi

echo "$NEW_MODE" > "$STATE_FILE"

sudo "$HOME/.local/bin/toggle-mode-reload.sh" "$LID_ACTION"

pkill -x hypridle
sleep 0.5
if [ "$NEW_MODE" = "server" ]; then
    hypridle -c "$HOME/.config/hypr/hypridle-server.conf" &
else
    hypridle &
fi
