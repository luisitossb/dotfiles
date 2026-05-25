#!/usr/bin/env python3
"""Regenerate pinned-modules.json and update the Waybar config from pinned-apps.json."""
import json, re, os, sys

home = os.environ['HOME']
pins_file   = f"{home}/.config/waybar/pinned-apps.json"
modules_file = f"{home}/.config/waybar/pinned-modules.json"
config_file  = f"{home}/.config/waybar/themes/glass-center/config"

def module_id(cls):
    return re.sub(r'[^a-zA-Z0-9]', '-', cls).lower()

def load_jsonc(path):
    with open(path) as f:
        content = f.read()
    # Strip // line comments that aren't inside strings
    content = re.sub(r'(?<!:)//[^\n]*', '', content)
    return json.loads(content)

with open(pins_file) as f:
    pins = json.load(f)

# ── Generate pinned-modules.json ──────────────────────────────────────────────
modules = {}
for p in pins:
    cls  = p['class']
    mid  = module_id(cls)
    icon = p['icon']
    name = p['name']
    exe  = p['exec']
    key  = f"custom/pin-{mid}"
    modules[key] = {
        "exec": f"waybar-pinned-check.sh '{cls}' '{icon}' '{name}'",
        "return-type": "json",
        "interval": 2,
        "on-click": f"waybar-pinned-launch.sh '{cls}' {exe}",
        "on-click-right": f"waybar-unpin.sh '{cls}'",
        "tooltip": True
    }

with open(modules_file, 'w') as f:
    json.dump(modules, f, indent=2)

# ── Update Waybar config ──────────────────────────────────────────────────────
pin_ids = [f"custom/pin-{module_id(p['class'])}" for p in pins]

config = load_jsonc(config_file)

# Ensure pinned-modules.json is included
includes = config.get("include", [])
pinned_include = "~/.config/waybar/pinned-modules.json"
if pinned_include not in includes:
    config["include"] = includes + [pinned_include]

# Pinned apps go in the center before the taskbar
config["modules-left"] = [
    "hyprland/workspaces",
    "custom/new-workspace",
    "custom/appmenu",
    "custom/empty"
]
config["modules-center"] = pin_ids + ["wlr/taskbar"]

# Exclude pinned classes from wlr/taskbar so they don't appear twice when running
pinned_classes = [p['class'] for p in pins]
if 'wlr/taskbar' not in config:
    config['wlr/taskbar'] = {}
config['wlr/taskbar']['ignore-list'] = ['Alacritty'] + pinned_classes

with open(config_file, 'w') as f:
    json.dump(config, f, indent=4)

print(f"Regenerated: {len(pins)} pinned apps")
