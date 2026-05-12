#!/bin/bash
CURRENT=$(brightnessctl --device "asus::kbd_backlight" get)
if [ "$CURRENT" -eq 0 ]; then
    printf '{"text":" off","tooltip":"Keyboard backlight off — click to cycle brightness","class":"off"}\n'
else
    printf '{"text":" %s/3","tooltip":"Keyboard backlight: %s/3 — click to cycle","class":"on"}\n' "$CURRENT" "$CURRENT"
fi
