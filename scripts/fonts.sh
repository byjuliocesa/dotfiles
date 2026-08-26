#!/usr/bin/env bash
# Fontes: instala tudo que está em assets/fonts/ em ~/.local/share/fonts.
# Fonte dos arquivos: https://www.programmingfonts.org (preview de fontes de código;
# cada uma linka o download oficial). CommitMono vem de https://commitmono.com.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

SOURCE_DIR="$ROOT_DIR/assets/fonts"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"

shopt -s nullglob globstar
fonts=("$SOURCE_DIR"/**/*.{otf,ttf})

if ((${#fonts[@]} == 0)); then
  warn "No fonts found in $SOURCE_DIR"
  exit 0
fi

changed=0
for font in "${fonts[@]}"; do
  family="$(basename "$(dirname "$font")")"
  target="$TARGET_DIR/$family/$(basename "$font")"
  if cmp -s "$font" "$target"; then
    continue
  fi
  mkdir -p "$(dirname "$target")"
  cp "$font" "$target"
  changed=1
  log "Installed font: $target"
done

if ((changed)); then
  command_exists fc-cache && fc-cache -f >/dev/null
  log "Font cache refreshed"
else
  log "Fonts already up to date"
fi
