#!/usr/bin/env bash
# Outputs JSON array: [{mac, name, connected}]
python3 << 'PYEOF'
import json, subprocess, sys

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

try:
    pairs_out = run(['bluetoothctl', 'devices', 'Paired'])
    if pairs_out.returncode != 0:
        raise RuntimeError("bluetoothctl exited %d: %s" % (pairs_out.returncode, pairs_out.stderr.strip()))

    devices = []
    for line in pairs_out.stdout.strip().split('\n'):
        parts = line.split()
        if len(parts) < 2:
            continue
        mac = parts[1]
        info = run(['bluetoothctl', 'info', mac]).stdout
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

except Exception as e:
    print("bt-devices: %s" % e, file=sys.stderr)
    print("[]")
PYEOF
