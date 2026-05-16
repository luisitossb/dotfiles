#!/bin/bash
set -euo pipefail
trap 'echo "[ERROR] mode-status.sh failed at line $LINENO (exit code: $?)" >&2' ERR
MODE=$(cat "$HOME/.config/mode/current" 2>/dev/null || echo "laptop")
if [ "$MODE" = "server" ]; then
    printf '{"text":"","tooltip":"Server mode: lid close → screen off only, no auto-suspend","class":"server"}\n'
else
    printf '{"text":"","tooltip":"Laptop mode: lid close → suspend","class":"laptop"}\n'
fi
