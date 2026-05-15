# Jellyfin OSD Timeout Fix

## What this does
Reduces the video player controls (OSD) hide delay from 3 seconds to 0.5 seconds.
Useful when switching to another screen — controls disappear much faster when the mouse leaves the player.

## Is this automated?
**Yes — a pacman hook handles it automatically.**
Files installed at:
- `/etc/pacman.d/hooks/jellyfin-osd-fix.hook` — triggers after every jellyfin install/upgrade
- `/usr/local/bin/jellyfin-osd-fix.sh` — the script that applies the fix

The hook fires whether you update via `pacman` or `paru` (paru is a pacman wrapper, hooks fire either way).

## Does this survive Jellyfin updates?
The pacman hook re-applies the fix automatically on every update, so yes — effectively permanent.
The hook finds the correct chunk file dynamically, so it handles filename hash changes between versions.

## Manual steps (if hook ever fails)

**1. Find the correct chunk file:**
```bash
grep -rl "osdHeader-hidden" /usr/share/jellyfin/web/*.chunk.js
```
Look for `playback-video.*.chunk.js` — the hash in the filename changes with each Jellyfin version.

**2. Apply the fix:**
```bash
sudo sed -E -i 's/=setTimeout\(([a-zA-Z]+),3e3\)/=setTimeout(\1,500)/g' /usr/share/jellyfin/web/playback-video.HASH.chunk.js
```

**3. Verify:**
```bash
grep -o ".\{30\}setTimeout(.,500).\{30\}" /usr/share/jellyfin/web/playback-video.HASH.chunk.js
```
Should print a line containing `setTimeout(...,500)`.

**4. Restart Jellyfin:**
```bash
sudo systemctl restart jellyfin
```

**5. Clear browser cache** (Ctrl+Shift+Delete → Cached Web Content), or test in incognito first.

## How the hook script works
The script (`/usr/local/bin/jellyfin-osd-fix.sh`):
1. Searches all chunk files for `osdHeader-hidden` (a stable class name that won't change)
2. Checks if the `3e3` pattern is present (skips if already patched)
3. Applies a flexible sed regex that handles minifier variable name changes
4. Restarts Jellyfin

## Notes
- `3e3` = JavaScript scientific notation for 3000ms. `500` = 0.5 seconds. Adjust in the hook script to taste.
- If the hook fails after an update, check if the class name `osdHeader-hidden` still exists in the chunk files.
- Source of truth in the Jellyfin repo: `src/controllers/playback/video/index.js` — search for `startOsdHideTimer`.
