#!/usr/bin/env bash
# Só garante o nvim; o bootstrap de verdade é Lua, rodando com nvim -l.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v nvim >/dev/null 2>&1; then
  command -v pacman >/dev/null 2>&1 || {
    echo "[dotfiles] Unsupported distro for now: install neovim and run again" >&2
    exit 1
  }
  sudo pacman -S --needed --noconfirm neovim
fi

exec nvim -l "$ROOT_DIR/lua/dotfiles/install.lua" "$@"
