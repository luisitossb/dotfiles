#!/bin/bash
set -euo pipefail
trap 'echo "[ERROR] start-hypridle.sh failed at line $LINENO (exit code: $?)" >&2' ERR
STATE_FILE="$HOME/.config/mode/current"
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop")
if [ "$MODE" = "server" ]; then
    exec hypridle -c "$HOME/.config/hypr/hypridle-server.conf"
else
    exec hypridle
fi
