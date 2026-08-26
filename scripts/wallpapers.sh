#!/usr/bin/env bash
# Wallpapers: copia assets/wallpapers/ para ~/Imagens/Wallpapers.
# Fonte dos arquivos: https://wallhaven.cc (os "wallhaven-xxxxxx.jpg" vêm de lá).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

SOURCE_DIR="$ROOT_DIR/assets/wallpapers"
TARGET_DIR="${XDG_PICTURES_DIR:-$HOME/Imagens}/Wallpapers"

mkdir -p "$TARGET_DIR"

shopt -s nullglob
wallpapers=("$SOURCE_DIR"/*)

if ((${#wallpapers[@]} == 0)); then
  warn "No wallpapers found in $SOURCE_DIR"
  exit 0
fi

for wallpaper in "${wallpapers[@]}"; do
  target="$TARGET_DIR/$(basename "$wallpaper")"
  if [[ -e "$target" ]]; then
    log "Wallpaper already exists: $target"
  else
    cp "$wallpaper" "$target"
    log "Copied wallpaper: $target"
  fi
done

