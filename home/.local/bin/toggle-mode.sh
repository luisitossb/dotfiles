#!/bin/bash
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

printf '[Login]\nHandleLidSwitch=%s\n' "$LID_ACTION" | sudo tee /etc/systemd/logind.conf.d/lid-mode.conf > /dev/null
sudo systemctl kill -s HUP systemd-logind

pkill -x hypridle
sleep 0.5
if [ "$NEW_MODE" = "server" ]; then
    hypridle -c "$HOME/.config/hypr/hypridle-server.conf" &
else
    hypridle &
fi
