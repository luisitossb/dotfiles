#!/bin/bash
if pgrep -x qs > /dev/null; then
    killall qs
else
    bash "$HOME/.config/quickshell/scripts/qs-autostart.sh"
fi
