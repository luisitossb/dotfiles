#!/usr/bin/env bash
# set-scroll.sh [mouse|trackpad] VALUE — updates scroll_factor in keyboard.conf
CONF="$HOME/.config/hypr/conf/keyboard.conf"
case "$1" in
    mouse)    sed -i "/# Scroll speed/s/scroll_factor = [0-9.]*/scroll_factor = $2/" "$CONF" ;;
    trackpad) sed -i "/# Touchpad scroll/s/scroll_factor = [0-9.]*/scroll_factor = $2/" "$CONF" ;;
esac
