#!/usr/bin/env bash
# Increment launch count for an app. Called by LauncherWindow on every launch.
# Usage: track-usage.sh <app_name>
export APP_NAME="$1"
python3 << 'PYEOF'
import json, os
name = os.environ.get("APP_NAME", "")
if not name:
    raise SystemExit(0)
f = os.path.expanduser("~/.local/share/qs-launcher/usage.json")
os.makedirs(os.path.dirname(f), exist_ok=True)
try:
    data = json.loads(open(f).read())
except Exception:
    data = {}
data[name] = data.get(name, 0) + 1
open(f, "w").write(json.dumps(data))
PYEOF
