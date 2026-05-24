#!/usr/bin/env bash
# Outputs JSON with all visible networks + saved connection names
python3 << 'PYEOF'
import json, subprocess, sys

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

try:
    radio = run(['nmcli', 'radio', 'wifi'])
    enabled = radio.returncode == 0 and 'enabled' in radio.stdout

    # Saved connection names
    saved = set()
    for line in run(['nmcli', '-t', '-f', 'NAME,TYPE', 'con', 'show']).stdout.strip().split('\n'):
        if '802-11-wireless' in line or ':wifi' in line:
            saved.add(line.rsplit(':', 1)[0])

    # Active connection
    active_ssid = ''
    for line in run(['nmcli', '-t', '-f', 'NAME,TYPE', 'con', 'show', '--active']).stdout.strip().split('\n'):
        if '802-11-wireless' in line or ':wifi' in line:
            active_ssid = line.rsplit(':', 1)[0]
            break

    networks = []
    seen = set()
    if enabled:
        raw = run(['nmcli', '--escape', 'no', '-t', '-f',
                   'SSID,SIGNAL,SECURITY,IN-USE', 'device', 'wifi', 'list'])
        for line in raw.stdout.strip().split('\n'):
            parts = line.split(':')
            if len(parts) < 4:
                continue
            ssid     = parts[0].strip()
            signal   = parts[1].strip()
            security = parts[2].strip()
            in_use   = parts[3].strip() == '*'
            if not ssid or ssid in seen:
                continue
            seen.add(ssid)
            networks.append({
                'ssid':     ssid,
                'signal':   int(signal) if signal.isdigit() else 0,
                'security': security,
                'saved':    ssid in saved,
                'connected': in_use or ssid == active_ssid
            })

    networks.sort(key=lambda x: (not x['connected'], not x['saved'], -x['signal']))
    print(json.dumps({'enabled': enabled, 'networks': networks, 'saved': list(saved)}))

except Exception as e:
    print("wifi-scan: %s" % e, file=sys.stderr)
    print(json.dumps({'enabled': False, 'networks': [], 'saved': []}))
PYEOF
