# Opera GX → Zen Browser Migration

## What transfers automatically (via Zen Sync)
- Bookmarks
- History
- Passwords
- Open tabs
- Addresses
- Add-ons
- Settings (browser preferences)
- Payment methods

## What you have to export/import manually
- **Bookmarks** — Opera Menu → Bookmarks → Export Bookmarks → `.html` → import in Zen
  - After importing, clean up bookmarks in Zen — Opera exports everything including trashed/deleted bookmarks and junk. Go through and remove those before considering it done.
- **Passwords** — Opera Settings → Advanced → Privacy & Security → Passwords → Export → `.csv` → import in Zen

## What you have to redo manually on each device
- **Look and Feel** — Zen's appearance customization (sidebar position, toolbar layout, colorways, compact mode, animations, tab bar behavior etc.) is Zen-specific and won't carry over via sync. Go through Settings → Look and Feel on each new device and set it up to your preference — it's one of Zen's best features so worth spending time on.
- **Search shortcuts** — not synced, add these in Zen Settings → Search:
  - YouTube: `https://www.youtube.com/results?search_query=%s`
  - Twitch: `https://www.twitch.tv/search?term=%s`
  - Amazon: included by default
- **Workspaces** — sync exists but is experimental/off by default, set up manually
- **Log into both Google accounts** — go to google.com → profile icon → Add another account, so "Login with Google" shows the account picker instead of auto-selecting one

## What doesn't transfer at all
- History (no export from Opera)
- Cookies (you'll just re-login to sites)
- Extensions (reinstall manually)
- Autofill addresses (no export)

## Setting Zen as default (Linux)
```bash
xdg-settings set default-web-browser zen.desktop  # default browser
xdg-mime default zen.desktop application/pdf       # local PDFs (optional)
```

## Setting Zen as default (Windows)
Windows Settings → Apps → Default Apps → search "Zen" → Set as default
- Covers web links and PDFs in one shot
- FTP default won't show Zen as an option (Windows limitation, only shows Chrome/Edge/Opera) — leave FTP on another browser or use FileZilla

## Performance settings (Windows)
Find your active profile via `about:profiles` → Open Directory, then create `user.js` in that folder:
```js
user_pref("gfx.webrender.all", true);
user_pref("layers.acceleration.force-enabled", true);
```
Note: VA-API and Wayland are Linux-only, skip those on Windows. WebRender is usually auto-enabled on Windows with up-to-date GPU drivers but force-enabling doesn't hurt.

To create via Claude Code on Windows terminal, run this prompt:
> Create a `user.js` file in my Zen Browser profile directory for performance settings. First find the active profile by running `Get-Content "$env:APPDATA\Zen\Profiles\profiles.ini"` to locate the active profile folder, then create a `user.js` file in that profile directory with these exact contents:
> ```js
> user_pref("gfx.webrender.all", true);
> user_pref("layers.acceleration.force-enabled", true);
> ```

## Notes
- Workspace sync is off by default in Zen — it exists but is buggy/experimental. Not worth enabling yet.
- Workspace tab sync only shows tabs from the currently active workspace on the other device, not all workspaces at once — known limitation of how Zen implements workspace isolation with Firefox's flat tab sync API.
- Zen on Linux: `MOZ_ENABLE_WAYLAND=1` already set via Hyprland, no action needed.
- Zen performance settings applied via `~/.config/zen/6goq41j0.Default (release)/user.js`
- Zen has a built-in PDF viewer, opens PDFs in-tab natively
- Zen displays .avif images in-browser fine but don't set it as default for local avif files — use Windows Photos or IrfanView instead
- Two Google accounts: log into both at google.com so "Login with Google" shows account picker instead of auto-selecting
