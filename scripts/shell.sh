#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

SOURCE_ALIASES="$ROOT_DIR/shell/aliases.sh"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
TARGET_ALIASES="$TARGET_DIR/aliases.sh"
SOURCE_LINE='[[ -r "$HOME/.config/shell/aliases.sh" ]] && source "$HOME/.config/shell/aliases.sh"'

SOURCE_FISH_CONFIG="$ROOT_DIR/config/fish/config.fish"
TARGET_FISH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
TARGET_FISH_CONFIG="$TARGET_FISH_DIR/config.fish"

SOURCE_TMUX_CONFIG="$ROOT_DIR/config/tmux/tmux.conf"
TARGET_TMUX_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
TARGET_TMUX_CONFIG="$TARGET_TMUX_DIR/tmux.conf"

install_aliases() {
  [[ -f "$SOURCE_ALIASES" ]] || return 0

  mkdir -p "$TARGET_DIR"
  cp "$SOURCE_ALIASES" "$TARGET_ALIASES"
  log "Installed shell aliases"
}

install_foot_config() {
  local src="$ROOT_DIR/config/foot/foot.ini"
  local dst="${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini"
  [[ -f "$src" ]] || return 0
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  log "Installed foot config"
}

install_fish_config() {
  [[ -f "$SOURCE_FISH_CONFIG" ]] || return 0

  mkdir -p "$TARGET_FISH_DIR"
  cp "$SOURCE_FISH_CONFIG" "$TARGET_FISH_CONFIG"
  log "Installed fish config"
}

install_tmux_config() {
  [[ -f "$SOURCE_TMUX_CONFIG" ]] || return 0

  mkdir -p "$TARGET_TMUX_DIR"
  cp "$SOURCE_TMUX_CONFIG" "$TARGET_TMUX_CONFIG"
  log "Installed tmux config"
}

ensure_shell_sources_aliases() {
  local rc_file="$1"

  [[ -f "$rc_file" ]] || return 0

  if grep -Fqx "$SOURCE_LINE" "$rc_file"; then
    return 0
  fi

  printf '\n%s\n' "$SOURCE_LINE" >>"$rc_file"
  log "Updated $(basename "$rc_file") to source shell aliases"
}

install_aliases
install_fish_config
install_foot_config
install_tmux_config
ensure_shell_sources_aliases "$HOME/.bashrc"
ensure_shell_sources_aliases "$HOME/.zshrc"
