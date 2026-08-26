#!/usr/bin/env bash
# Cursor: plugin hypr-dynamic-cursors (tilt + shake to find) e tema Hatsune Miku.
# Fonte dos temas de cursor: GitHub (procurar por "cursor theme"; o atual é o
# repositório em CURSOR_REPO abaixo).
# O plugin é compilado manualmente porque hyprpm exige sudo e o commit precisa
# bater com a versão exata do Hyprland instalada (pinos em hyprpm.toml).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

PLUGIN_REPO="https://github.com/VirtCode/hypr-dynamic-cursors"
PLUGIN_SRC="$HOME/.local/src/hypr-dynamic-cursors"
PLUGIN_DIR="$HOME/.local/lib/hyprland-plugins"

CURSOR_REPO="https://github.com/supermariofps/hatsune-miku-windows-linux-cursors"
CURSOR_THEME="miku-cursor-linux"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

install_dynamic_cursors() {
  command_exists hyprctl || { warn "Skipping dynamic-cursors: Hyprland not installed"; return 0; }
  for dep in git make g++ pkg-config; do
    command_exists "$dep" || { warn "Skipping dynamic-cursors: missing $dep"; return 0; }
  done

  if [[ -d "$PLUGIN_SRC/.git" ]]; then
    git -C "$PLUGIN_SRC" fetch -q origin main
  else
    git clone -q "$PLUGIN_REPO" "$PLUGIN_SRC"
  fi

  local hypr_commit plugin_commit
  hypr_commit="$(hyprctl version 2>/dev/null | grep -oPm1 'commit \K[0-9a-f]+' || true)"
  if [[ -z "$hypr_commit" ]]; then
    warn "Skipping dynamic-cursors: could not read Hyprland version (is Hyprland running?)"
    return 0
  fi
  plugin_commit="$(git -C "$PLUGIN_SRC" show origin/main:hyprpm.toml | grep "\"$hypr_commit\"" | grep -oP '"\K[0-9a-f]{40}(?="\],)' || true)"
  if [[ -z "$plugin_commit" ]]; then
    plugin_commit="origin/main"
    warn "No pinned dynamic-cursors commit for Hyprland $hypr_commit; building main (may fail)"
  fi

  git -C "$PLUGIN_SRC" checkout -q "$plugin_commit"
  make -C "$PLUGIN_SRC" clean all -j"$(nproc)" >/dev/null

  # Nunca sobrescrever o .so no lugar: o Hyprland mantém o arquivo mapeado em
  # memória e um cp por cima derruba o compositor. mv troca o inode atomicamente.
  mkdir -p "$PLUGIN_DIR"
  if cmp -s "$PLUGIN_SRC/out/dynamic-cursors.so" "$PLUGIN_DIR/dynamic-cursors.so"; then
    log "dynamic-cursors plugin already up to date"
    return 0
  fi
  cp "$PLUGIN_SRC/out/dynamic-cursors.so" "$PLUGIN_DIR/dynamic-cursors.so.new"
  mv -f "$PLUGIN_DIR/dynamic-cursors.so.new" "$PLUGIN_DIR/dynamic-cursors.so"
  log "Installed dynamic-cursors plugin to $PLUGIN_DIR (commit ${plugin_commit:0:7}); takes effect on next Hyprland start"
}

install_miku_cursor() {
  if [[ -d "$ICONS_DIR/$CURSOR_THEME" ]]; then
    log "Cursor theme $CURSOR_THEME already installed"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  git clone -q --depth 1 "$CURSOR_REPO" "$tmp/repo"
  mkdir -p "$ICONS_DIR/default"
  cp -r "$tmp/repo/$CURSOR_THEME" "$ICONS_DIR/"
  printf '[Icon Theme]\nInherits=%s\n' "$CURSOR_THEME" > "$ICONS_DIR/default/index.theme"
  rm -rf "$tmp"
  log "Installed cursor theme $CURSOR_THEME"
}

install_dynamic_cursors
install_miku_cursor
