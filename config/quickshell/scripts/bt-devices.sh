#!/usr/bin/env bash
# Outputs JSON array: [{mac, name, connected}]
python3 << 'PYEOF'
import json, subprocess

pairs = subprocess.run(['bluetoothctl', 'devices', 'Paired'],
    capture_output=True, text=True).stdout.strip()

devices = []
for line in pairs.split('\n'):
    parts = line.split()
    if len(parts) < 2:
        continue
    mac = parts[1]
    info = subprocess.run(['bluetoothctl', 'info', mac], capture_output=True, text=True).stdout
    name = mac
    connected = False
    for il in info.split('\n'):
        il = il.strip()
        if il.startswith('Alias:'):
            name = il[6:].strip()
        elif il.startswith('Name:') and name == mac:
            name = il[5:].strip()
        elif il == 'Connected: yes':
            connected = True
    devices.append({'mac': mac, 'name': name, 'connected': connected})

print(json.dumps(devices))
PYEOF
