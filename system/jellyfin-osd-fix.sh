#!/bin/bash
WEBDIR=/usr/share/jellyfin/web

# Find the chunk containing the OSD hide class (stable across versions)
CHUNK=$(grep -rl "osdHeader-hidden" "$WEBDIR"/*.chunk.js 2>/dev/null | head -1)

if [ -z "$CHUNK" ]; then
    echo "jellyfin-osd-fix: no matching chunk found, skipping"
    exit 0
fi

if grep -q "setTimeout(.*,3e3)" "$CHUNK"; then
    # Flexible regex handles minifier variable name changes between versions
    sed -E -i 's/=setTimeout\(([a-zA-Z]+),3e3\)/=setTimeout(\1,500)/g' "$CHUNK"
    echo "jellyfin-osd-fix: patched OSD timeout to 500ms in $(basename "$CHUNK")"
    systemctl restart jellyfin
    echo "jellyfin-osd-fix: Jellyfin restarted"
else
    echo "jellyfin-osd-fix: pattern not found in $(basename "$CHUNK") — may already be patched or version changed"
fi
