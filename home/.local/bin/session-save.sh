#!/usr/bin/env bash
# Snapshot current Hyprland window layout before a reboot
SESSION_FILE="$HOME/.local/share/hypr-session"

hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
seen = set()
for c in sorted(clients, key=lambda x: x['workspace']['id']):
    key = (c['workspace']['id'], c['class'])
    if key not in seen:
        seen.add(key)
        print(f\"{c['workspace']['id']} {c['class']}\")
" > "$SESSION_FILE"

count=$(wc -l < "$SESSION_FILE")
notify-send "Session saved" "$count apps snapshotted — safe to reboot" 2>/dev/null
echo "Session saved ($count apps):"
cat "$SESSION_FILE"
