#!/bin/bash
# Restart Quickshell safely.
# If it's already stopped, just starts it.
# WARNING: if your terminal was launched through Quickshell's app launcher,
#          the restart will close it — open a fresh terminal first.

if systemctl --user is-active --quiet quickshell; then
    echo "Quickshell is running — restarting..."
    systemctl --user restart quickshell
    echo "Done."
else
    echo "Quickshell is not running — starting..."
    systemctl --user start quickshell
    echo "Done."
fi
