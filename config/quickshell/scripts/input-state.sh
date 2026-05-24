#!/usr/bin/env bash
CONF="$HOME/.config/hypr/conf/keyboard.conf"
ms=$(grep '# Scroll speed'         "$CONF" | grep -oP 'scroll_factor = \K[0-9.]+')
msens=$(grep '# mouse-sensitivity' "$CONF" | grep -oP 'sensitivity = \K[-0-9.]+')
ts=$(grep '# Touchpad scroll'      "$CONF" | grep -oP 'scroll_factor = \K[0-9.]+')
tsens=$(grep '# trackpad-sensitivity' "$CONF" | grep -oP 'sensitivity = \K[-0-9.]+')
nat=$(grep 'natural_scroll'        "$CONF" | grep -oP 'natural_scroll = \K\w+')
nl=$(grep 'numlock_by_default'     "$CONF" | grep -oP 'numlock_by_default = \K\w+')
kbl=$(grep 'kb_layout'             "$CONF" | grep -oP 'kb_layout = \K\w+')
accel=$(grep 'accel_profile'       "$CONF" | grep -oP 'accel_profile = \K\w+')
printf '{"ms":%s,"msens":%s,"ts":%s,"tsens":%s,"nat":%s,"nl":%s,"kbl":"%s","accel":"%s"}\n' \
    "${ms:-0.75}" "${msens:-0}" "${ts:-0.85}" "${tsens:-0}" \
    "${nat:-false}" "${nl:-true}" "${kbl:-us}" "${accel:-flat}"
