#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

install_yay() {
  if command_exists yay || command_exists paru; then
    log "AUR helper already installed"
    return 0
  fi

  local build_dir
  build_dir="$(mktemp -d)"
  trap 'rm -rf "$build_dir"' EXIT

  log "Installing yay-bin from AUR"
  git clone https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
  makepkg -si --noconfirm --needed -C "$build_dir/yay-bin"
}

install_yay
