#!/bin/bash
# Pick a random Gen 1 Pokemon sprite and set it as ~/.face-fastfetch
# Sprites are cached in ~/.cache/pokemon-sprites/ to avoid re-downloading

CACHE_DIR="$HOME/.cache/pokemon-sprites"
TARGET="$HOME/.face-fastfetch"
mkdir -p "$CACHE_DIR"

# Random Gen 1 Pokemon (1-151)
ID=$(( RANDOM % 151 + 1 ))
CACHED="$CACHE_DIR/$ID.png"

if [[ ! -f "$CACHED" ]]; then
    curl -s "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$ID.png" \
         -o "$CACHED" 2>/dev/null
fi

# Fall back to last used sprite if download failed
if [[ -f "$CACHED" ]]; then
    cp "$CACHED" "$TARGET"
fi
