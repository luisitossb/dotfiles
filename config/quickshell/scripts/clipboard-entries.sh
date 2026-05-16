#!/usr/bin/env bash
# Outputs JSON array of cliphist entries; decodes PNG images to /tmp/qs-clipboard-cache/
python3 << 'PYEOF'
import subprocess, json, os, hashlib

CACHE_DIR = "/tmp/qs-clipboard-cache"
os.makedirs(CACHE_DIR, exist_ok=True)

def run(cmd):
    return subprocess.run(cmd, capture_output=True).stdout

list_out = run(["cliphist", "list"]).decode(errors="replace")
entries = []

for line in list_out.splitlines():
    if not line.strip():
        continue
    tab_idx = line.find("\t")
    if tab_idx == -1:
        continue
    entry_id = line[:tab_idx]
    preview  = line[tab_idx+1:]

    is_image = False
    img_path = ""
    if preview.strip().startswith("[[ binary") or preview.strip().startswith("[[binary"):
        raw = run(["cliphist", "decode", entry_id])
        if raw[:8] == b'\x89PNG\r\n\x1a\n':
            h = hashlib.md5(entry_id.encode()).hexdigest()
            img_path = os.path.join(CACHE_DIR, h + ".png")
            if not os.path.exists(img_path):
                with open(img_path, "wb") as f:
                    f.write(raw)
            is_image = True
            preview  = "[Image]"

    entries.append({
        "id":       entry_id,
        "preview":  preview[:120],
        "is_image": is_image,
        "img_path": img_path,
    })

print(json.dumps(entries[:80]))
PYEOF
