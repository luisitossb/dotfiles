#!/usr/bin/env bash
# Usage: set-nightmode.sh enable|disable|temp VALUE
STATE="$HOME/.config/quickshell/state/nightmode-temp"
case "$1" in
    enable)
        TEMP=$(cat "$STATE" 2>/dev/null || echo "4000")
        pkill -x hyprsunset 2>/dev/null
        sleep 0.1
        hyprsunset -t "$TEMP" &
        ;;
    disable)
        pkill -x hyprsunset 2>/dev/null
        ;;
    temp)
        echo "$2" > "$STATE"
        if pgrep -x hyprsunset >/dev/null 2>&1; then
            pkill -x hyprsunset
            sleep 0.1
            hyprsunset -t "$2" &
        fi
        ;;
esac
