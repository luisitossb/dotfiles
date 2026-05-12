#!/bin/bash
DEVICE="asus::kbd_backlight"
CURRENT=$(brightnessctl --device "$DEVICE" get)
MAX=$(brightnessctl --device "$DEVICE" max)
NEXT=$(( (CURRENT + 1) % (MAX + 1) ))
brightnessctl --device "$DEVICE" set "$NEXT"
