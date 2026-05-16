#!/usr/bin/env bash
# Outputs JSON array of installed .desktop apps for the Quickshell launcher
python3 << 'PYEOF'
import os, json, sys

XDG_DIRS = [
    os.path.expanduser("~/.local/share/applications"),
    "/usr/local/share/applications",
    "/usr/share/applications",
]

ICON_SIZES = ["48", "32", "64", "24", "128", "256", "22", "16"]
ICON_THEMES_DIR = "/usr/share/icons"
PIXMAPS_DIR = "/usr/share/pixmaps"

def find_icon(name):
    if not name:
        return ""
    if os.path.isabs(name) and os.path.exists(name):
        return name
    for theme in ["hicolor", "breeze", "Adwaita", "Papirus", "Papirus-Dark"]:
        theme_dir = os.path.join(ICON_THEMES_DIR, theme)
        if not os.path.isdir(theme_dir):
            continue
        for size in ICON_SIZES:
            for cat in ["apps", "devices", "places", "status", "mimetypes"]:
                for ext in ["svg", "png"]:
                    p = os.path.join(theme_dir, size + "x" + size, cat, name + "." + ext)
                    if os.path.exists(p):
                        return p
        for cat in ["apps", "devices", "places", "status", "mimetypes"]:
            p = os.path.join(theme_dir, "scalable", cat, name + ".svg")
            if os.path.exists(p):
                return p
    for ext in ["png", "svg", "xpm"]:
        p = os.path.join(PIXMAPS_DIR, name + "." + ext)
        if os.path.exists(p):
            return p
    return ""

def parse_desktop(path):
    entry = {}
    in_desktop_entry = False
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if line == "[Desktop Entry]":
                    in_desktop_entry = True
                    continue
                if line.startswith("[") and line != "[Desktop Entry]":
                    in_desktop_entry = False
                    continue
                if not in_desktop_entry or "=" not in line:
                    continue
                k, _, v = line.partition("=")
                entry[k.strip()] = v.strip()
    except Exception as e:
        print("app-list: failed to parse %s: %s" % (path, e), file=sys.stderr)
        return None
    if entry.get("Type") != "Application":
        return None
    if entry.get("NoDisplay", "false").lower() == "true":
        return None
    if entry.get("Hidden", "false").lower() == "true":
        return None
    name = entry.get("Name", "")
    exec_raw = entry.get("Exec", "")
    if not name or not exec_raw:
        return None
    exec_clean = " ".join(p for p in exec_raw.split() if not p.startswith("%"))
    icon_name = entry.get("Icon", "")
    return {
        "name":      name,
        "exec":      exec_clean,
        "icon":      find_icon(icon_name),
        "icon_name": icon_name,
        "comment":   entry.get("Comment", ""),
        "terminal":  entry.get("Terminal", "false").lower() == "true",
    }

try:
    usage_file = os.path.expanduser("~/.local/share/qs-launcher/usage.json")
    try:
        usage = json.loads(open(usage_file).read())
    except Exception:
        usage = {}

    seen_names = set()
    apps = []

    for d in XDG_DIRS:
        if not os.path.isdir(d):
            continue
        for fname in sorted(os.listdir(d)):
            if not fname.endswith(".desktop"):
                continue
            app = parse_desktop(os.path.join(d, fname))
            if app and app["name"] not in seen_names:
                seen_names.add(app["name"])
                app["count"] = usage.get(app["name"], 0)
                apps.append(app)

    apps.sort(key=lambda a: (-a["count"], a["name"].lower()))
    print(json.dumps(apps))

except Exception as e:
    print("app-list: %s" % e, file=sys.stderr)
    print("[]")
PYEOF
