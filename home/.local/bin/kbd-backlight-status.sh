#!/bin/bash
CURRENT=$(brightnessctl --device "asus::kbd_backlight" get)
if [ "$CURRENT" -eq 0 ]; then
    printf '{"text":"󰌶","tooltip":"Keyboard backlight off — click to cycle brightness","class":"off"}\n'
elif [ "$CURRENT" -eq 1 ]; then
    printf '{"text":"󱩎","tooltip":"Keyboard backlight: 1/3 — click to cycle","class":"on"}\n'
elif [ "$CURRENT" -eq 2 ]; then
    printf '{"text":"󱩏","tooltip":"Keyboard backlight: 2/3 — click to cycle","class":"on"}\n'
else
    printf '{"text":"󱩐","tooltip":"Keyboard backlight: 3/3 — click to cycle","class":"on"}\n'
fi
