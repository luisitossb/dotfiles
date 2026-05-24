#!/bin/bash
# View Quickshell logs.
# Usage:
#   qs-log          — follow live logs (Ctrl+C to stop)
#   qs-log -n 50    — show last 50 lines and exit
#   qs-log -e       — show only errors and warnings

case "$1" in
    -n)
        journalctl --user -u quickshell -n "${2:-50}" --no-pager
        ;;
    -e)
        journalctl --user -u quickshell -n 200 --no-pager \
            | grep -E "ERROR|WARN|error|warn|qml"
        ;;
    *)
        echo "Following Quickshell logs (Ctrl+C to stop)..."
        journalctl --user -u quickshell -f
        ;;
esac
