# Media Renaming Reference for Jellyfin

## Target File Naming Format
```
Show Name - S01E01 - Episode Title.ext
```
Examples:
- `The Legend of Korra - S01E01 - Welcome to Republic City.mkv`
- `Young Sheldon - S07E01 - A Wiener Schnitzel and Underwear in a Tree.mkv`
- `Avatar - The Last Airbender - S01E01 - The Boy in the Iceberg.mp4`

Rules:
- No year in show name (e.g. `Pokemon` not `Pokemon (1997)`)
- No encoding info (strip anything like `(1080p NF WEB-DL x265 iBSiCUS)`, `[bonkai77]`, `.Bluray.`, etc.)
- No release group tags
- Always zero-pad episode numbers: E01 not E1, S01 not S1
- Preserve special characters in episode titles (!, ', &, …, commas)
- Preserve dots that are part of titles (e.g. episode titled "1.28" stays "1.28")

## Folder Structure
```
Shows/
└── Show Name/
    ├── Season 1/
    │   └── Show Name - S01E01 - Title.mkv
    ├── Season 2/
    └── Specials/   (for S00Exx files)

Movies/
└── Movie Name (Year)/
    └── Movie Name (Year).mkv
```

Rules:
- Each show gets its own parent folder
- Season subfolders named exactly `Season 1`, `Season 2`, etc. (not `S01`, `Book 1`, etc.)
- Never mix shows in the same folder
- Never mix seasons in the same folder

## Common Source Patterns → Target

| Source Pattern | Example | Action |
|---|---|---|
| `Show (Year) - S01E01 - Title (1080p ...).mkv` | Young Sheldon S7 | Strip year and encoding |
| `Show.S01E01.Title.1080p.encoding.mkv` | Young Sheldon S6 | Replace dots with spaces, strip encoding |
| `[group].Show.Episode.01.Title.1080p.mkv` | Death Note | Strip group tag, convert to S01E01 |
| `101 - Title.mp4` | Avatar | First digit = season, last two = episode → S01E01 |
| `Book 1; Water/` folder | Avatar | Rename to `Season 1/` |

## Always Do Before Renaming
1. Check total episode count per folder
2. Verify episode 1 title matches TheTVDB to confirm correct season numbering
3. Do a **dry run first** and show the user before applying
4. Ask the user to confirm before applying

## Known Show-Specific Issues

### Workaholics
- Source files include `(2008)` year tag in show name — strip it
- Folder already ships with correct `Season 1` through `Season 7` subfolders, no restructuring needed
- Just strip encoding and year from filenames

## Known Season Number Issues (Pokemon)
Pokemon season numbering varies by torrent source vs TheTVDB:
- TheTVDB S16 = Adventures in Unova (Black & White era)
- TheTVDB S17 = XY
- TheTVDB S18 = XY Kalos Quest
- TheTVDB S19 = XYZ
- TheTVDB S20+ = Sun & Moon onwards

Always verify episode 1 title against TheTVDB before trusting the torrent's season number.

## After Renaming
Tell user to:
1. Refresh Jellyfin library (scan for new content)
2. Go to series → three-dot menu → **Identify** → confirm TheTVDB match
3. Three-dot menu → **Refresh Metadata** → check "Replace all metadata" + "Replace all images"

## Media Location
All media lives under: `/home/luisito/Desktop/Files I own/`
- Shows: `/home/luisito/Desktop/Files I own/Shows/`
- Movies: `/home/luisito/Desktop/Files I own/Movies/`
