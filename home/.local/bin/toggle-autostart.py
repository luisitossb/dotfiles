#!/usr/bin/env python3
import re, sys, os

CONF = os.path.expanduser("~/.config/hypr/conf/autostart.conf")
target = sys.argv[1].strip()

with open(CONF) as f:
    lines = f.readlines()

out = []
for line in lines:
    s = line.strip()
    m = re.match(r'^exec-once\s*=\s*(.+)$', s)
    if m and m.group(1).strip() == target:
        out.append(f'# exec-once = {target}\n')
        continue
    m = re.match(r'^#\s*exec-once\s*=\s*(.+)$', s)
    if m and m.group(1).strip() == target:
        out.append(f'exec-once = {target}\n')
        continue
    out.append(line)

with open(CONF, 'w') as f:
    f.writelines(out)
