#!/usr/bin/env bash
vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.50")
vol_pct=$(echo "$vol_raw" | grep -oP '[0-9]+\.[0-9]+' | head -1 | awk '{printf "%d", $1*100}')
muted=$(echo "$vol_raw" | grep -q MUTED && echo true || echo false)

mic_raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo "Volume: 1.00")
mic_pct=$(echo "$mic_raw" | grep -oP '[0-9]+\.[0-9]+' | head -1 | awk '{printf "%d", $1*100}')
mic_muted=$(echo "$mic_raw" | grep -q MUTED && echo true || echo false)

bright=$(brightnessctl -m 2>/dev/null | awk -F, '{gsub("%","",$4); print $4}')
night=$(pgrep -x hyprsunset >/dev/null 2>&1 && echo true || echo false)
night_temp=$(cat "$HOME/.config/quickshell/state/nightmode-temp" 2>/dev/null || echo "4000")

printf '{"vol":%s,"muted":%s,"mic":%s,"micMuted":%s,"bright":%s,"night":%s,"nightTemp":%s}\n' \
    "${vol_pct:-50}" "$muted" "${mic_pct:-100}" "$mic_muted" \
    "${bright:-100}" "$night" "$night_temp"
