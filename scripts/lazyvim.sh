#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

SOURCE_NVIM_DIR="$ROOT_DIR/config/nvim"
TARGET_NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

install_lazyvim_config() {
  [[ -d "$SOURCE_NVIM_DIR" ]] || {
    warn "Skipping LazyVim because config/nvim is missing"
    return 0
  }

  command_exists nvim || {
    warn "Skipping LazyVim config because neovim is not installed"
    return 0
  }

  mkdir -p "$(dirname "$TARGET_NVIM_DIR")"

  if [[ -e "$TARGET_NVIM_DIR" && ! -L "$TARGET_NVIM_DIR" ]]; then
    local backup="$TARGET_NVIM_DIR.bak.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET_NVIM_DIR" "$backup"
    log "Backed up existing nvim config to $backup"
  elif [[ -L "$TARGET_NVIM_DIR" ]]; then
    rm "$TARGET_NVIM_DIR"
  fi

  cp -a "$SOURCE_NVIM_DIR" "$TARGET_NVIM_DIR"
  log "Installed LazyVim config"

  log "Bootstrapping LazyVim plugins (first run may take a while)"
  nvim --headless "+Lazy! sync" +qa
  cp "$TARGET_NVIM_DIR/lazy-lock.json" "$SOURCE_NVIM_DIR/lazy-lock.json" 2>/dev/null || true
  log "LazyVim plugins synced"
}

install_lazyvim_config
