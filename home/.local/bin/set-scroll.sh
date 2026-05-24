#!/usr/bin/env bash
# Usage: set-scroll.sh mouse    scroll|sens VALUE
#                      trackpad scroll|sens VALUE
#                      natural  true|false
#                      numlock  true|false
CONF="$HOME/.config/hypr/conf/keyboard.conf"
case "$1" in
    mouse)
        case "$2" in
            scroll)
                sed -i "/# Scroll speed/s/scroll_factor = [0-9.]*/scroll_factor = $3/" "$CONF"
                hyprctl keyword input:scroll_factor "$3" -q 2>/dev/null || true
                ;;
            sens)
                sed -i "/# mouse-sensitivity/s/sensitivity = [-0-9.]*/sensitivity = $3/" "$CONF"
                hyprctl keyword "device[2.4g-mouse-1]:sensitivity" "$3" -q 2>/dev/null || true
                ;;
        esac ;;
    trackpad)
        case "$2" in
            scroll)
                sed -i "/# Touchpad scroll/s/scroll_factor = [0-9.]*/scroll_factor = $3/" "$CONF"
                hyprctl keyword input:touchpad:scroll_factor "$3" -q 2>/dev/null || true
                ;;
            sens)
                sed -i "/# trackpad-sensitivity/s/sensitivity = [-0-9.]*/sensitivity = $3/" "$CONF"
                hyprctl keyword "device[elan1200:00-04f3:307a-touchpad]:sensitivity" "$3" -q 2>/dev/null || true
                ;;
        esac ;;
    natural)
        sed -i "s/natural_scroll = .*/natural_scroll = $2/" "$CONF"
        hyprctl keyword input:touchpad:natural_scroll "$2" -q 2>/dev/null || true
        ;;
    numlock)
        sed -i "s/numlock_by_default = .*/numlock_by_default = $2/" "$CONF"
        hyprctl keyword input:numlock_by_default "$2" -q 2>/dev/null || true
        ;;
    accel)
        sed -i "s/accel_profile = .*/accel_profile = $2/" "$CONF"
        hyprctl keyword input:accel_profile "$2" -q 2>/dev/null || true
        ;;
esac
