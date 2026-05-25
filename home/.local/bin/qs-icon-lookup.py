#!/usr/bin/env python3
"""Look up SVG icon path for an app class name via GTK icon theme.
Usage: qs-icon-lookup.py <class-name>
Prints icon file path on success, exits 1 on failure.
"""
import sys

try:
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk
except Exception:
    sys.exit(1)

if len(sys.argv) < 2 or not sys.argv[1].strip():
    sys.exit(1)

cls = sys.argv[1].strip()
theme = Gtk.IconTheme.get_default()

candidates = [cls, cls.lower(), cls.replace(' ', '-').lower()]
if '.' in cls:
    parts = cls.split('.')
    candidates.append(parts[-1])
    candidates.append(parts[-1].lower())
    candidates.append('-'.join(p.lower() for p in parts))

for c in candidates:
    if not c:
        continue
    info = theme.lookup_icon(c, 48, 0)
    if info:
        path = info.get_filename()
        if path:
            print(path)
            sys.exit(0)

sys.exit(1)
