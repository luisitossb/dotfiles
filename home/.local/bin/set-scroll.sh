#!/usr/bin/env bash
# set-scroll.sh [mouse|trackpad] [scroll|sens] VALUE
CONF="$HOME/.config/hypr/conf/keyboard.conf"
case "$1-$2" in
    mouse-scroll)    sed -i "/# Scroll speed/s/scroll_factor = [0-9.]*/scroll_factor = $3/" "$CONF" ;;
    trackpad-scroll) sed -i "/# Touchpad scroll/s/scroll_factor = [0-9.]*/scroll_factor = $3/" "$CONF" ;;
    mouse-sens)      sed -i "/# mouse-sensitivity/s/sensitivity = [-0-9.]*/sensitivity = $3/" "$CONF" ;;
    trackpad-sens)   sed -i "/# trackpad-sensitivity/s/sensitivity = [-0-9.]*/sensitivity = $3/" "$CONF" ;;
esac
