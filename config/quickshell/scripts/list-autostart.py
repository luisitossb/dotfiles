#!/usr/bin/env python3
import re, json, os

CONF = os.path.expanduser("~/.config/hypr/conf/autostart.conf")

NAME_MAP = {
    "low-bat-notification":                  "Battery Alert",
    "gtk-theme-switcher":                    "GTK Theme Sync",
    "polkit-gnome-authentication-agent-1":   "Auth Agent (Polkit)",
    "qs-autostart":                          "Quickshell",
    "gtk":                                   "GTK Settings",
    "start-hypridle":                        "Screen Lock (hypridle)",
    "wl-paste":                              "Clipboard History",
    "cleanup":                               "Autostart Cleanup",
    "cascade-workspaces":                    "Workspace Cascade",
    "kitty":                                 "Terminal (Workspace 1)",
    "dbus-update-activation-environment":    "D-Bus Session",
}

entries = []
with open(CONF) as f:
    for line in f:
        stripped = line.strip()
        enabled = True
        m = re.match(r'^exec-once\s*=\s*(.+)$', stripped)
        if not m:
            m = re.match(r'^#\s*exec-once\s*=\s*(.+)$', stripped)
            enabled = False
        if not m:
            continue
        cmd = m.group(1).strip()
        cmd_clean = re.sub(r'^\[.*?\]\s*', '', cmd)
        binary = os.path.basename(cmd_clean.split()[0])
        binary = re.sub(r'\.(sh|py)$', '', binary)
        name = NAME_MAP.get(binary, binary.replace('-', ' ').replace('_', ' ').title())
        entries.append({"name": name, "cmd": cmd, "enabled": enabled})

print(json.dumps(entries))
