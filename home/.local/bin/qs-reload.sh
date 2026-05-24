#!/bin/bash
# Hot-reload Quickshell config and theme without restarting.
# QML file changes are picked up automatically via inotify —
# this additionally triggers a theme color reload.

if ! systemctl --user is-active --quiet quickshell; then
    echo "Quickshell is not running. Use qs-safe-restart instead."
    exit 1
fi

qs ipc call theme-manager reload
echo "Theme reloaded. (QML file changes are picked up automatically.)"
