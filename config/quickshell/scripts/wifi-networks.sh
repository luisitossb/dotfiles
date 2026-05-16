#!/usr/bin/env bash
# Outputs JSON: {enabled, networks: [{name, connected}]}
python3 << 'PYEOF'
import json, subprocess, sys

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

try:
    radio = run(['nmcli', 'radio', 'wifi'])
    if radio.returncode != 0:
        raise RuntimeError("nmcli not available: %s" % radio.stderr.strip())
    enabled = 'enabled' in radio.stdout

    active = ''
    for line in run(['nmcli', '-t', '-f', 'NAME,TYPE', 'con', 'show', '--active']).stdout.strip().split('\n'):
        if ':wifi' in line or ':802-11-wireless' in line:
            active = line.rsplit(':', 1)[0]
            break

    networks = []
    for line in run(['nmcli', '-t', '-f', 'NAME,TYPE', 'con', 'show']).stdout.strip().split('\n'):
        if ':wifi' in line or ':802-11-wireless' in line:
            name = line.rsplit(':', 1)[0]
            networks.append({'name': name, 'connected': name == active})

    networks.sort(key=lambda x: (not x['connected'], x['name'].lower()))
    print(json.dumps({'enabled': enabled, 'networks': networks}))

except Exception as e:
    print("wifi-networks: %s" % e, file=sys.stderr)
    print(json.dumps({'enabled': False, 'networks': []}))
PYEOF
