#!/usr/bin/env bash

set -euo pipefail

SRC="${1:-}"
LAST_FILE="$HOME/.cache/wallpaper_picker/current_wallpaper"

if [ -z "$SRC" ] && [ -f "$LAST_FILE" ]; then
  SRC="$(cat "$LAST_FILE")"
fi

if [ -z "$SRC" ]; then
  if pgrep -a "mpvpaper" >/dev/null 2>&1; then
    SRC="$(pgrep -a mpvpaper | grep -o "$HOME/Pictures/WallPaper/[^' ]*" | head -n1)"
  fi
fi

if [ -z "$SRC" ] && command -v swww >/dev/null 2>&1; then
  # Try to grab any path from swww (may include file:// prefix)
  SRC="$(swww query 2>/dev/null | grep -oE '(file://)?/[^ ]+' | head -n1)"
fi

if [ -z "$SRC" ]; then
  exit 0
fi

# Strip file:// if present
SRC="${SRC#file://}"

OUT_DIR="$HOME/.cache/hyprlock-cache"
OUT_FILE="$OUT_DIR/wallpaper.png"

mkdir -p "$OUT_DIR"

ext="${SRC##*.}"
ext_lc="$(printf "%s" "$ext" | tr '[:upper:]' '[:lower:]')"

case "$ext_lc" in
  mp4|mkv|mov|webm)
    ffmpeg -y -ss 00:00:01 -i "$SRC" -vframes 1 -vf "scale=iw:ih" "$OUT_FILE" >/dev/null 2>&1 || true
    ;;
  *)
    cp -f "$SRC" "$OUT_FILE"
    ;;
esac
