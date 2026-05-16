#!/usr/bin/env bash
# Outputs JSON: {enabled, networks: [{name, connected}]}
python3 << 'PYEOF'
import json, subprocess

enabled = 'enabled' in subprocess.run(
    ['nmcli', 'radio', 'wifi'], capture_output=True, text=True).stdout

active = ''
for line in subprocess.run(
        ['nmcli', '-t', '-f', 'NAME,TYPE', 'con', 'show', '--active'],
        capture_output=True, text=True).stdout.strip().split('\n'):
    if ':wifi' in line or ':802-11-wireless' in line:
        active = line.rsplit(':', 1)[0]
        break

networks = []
for line in subprocess.run(
        ['nmcli', '-t', '-f', 'NAME,TYPE', 'con', 'show'],
        capture_output=True, text=True).stdout.strip().split('\n'):
    if ':wifi' in line or ':802-11-wireless' in line:
        name = line.rsplit(':', 1)[0]
        networks.append({'name': name, 'connected': name == active})

networks.sort(key=lambda x: (not x['connected'], x['name'].lower()))
print(json.dumps({'enabled': enabled, 'networks': networks}))
PYEOF
