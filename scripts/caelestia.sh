#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

caelestia_installed() {
  [[ -d "$HYPR_CONFIG_DIR" ]] && compgen -G "$HYPR_CONFIG_DIR/*" >/dev/null
}

install_caelestia_dots() {
  command_exists caelestia || {
    warn "Skipping Caelestia dots because caelestia-cli is not installed"
    return 0
  }

  if pacman -Q jack2 >/dev/null 2>&1; then
    log "Removing jack2 to avoid conflict with pipewire-jack (common on KDE installs)"
    run_sudo pacman -Rdd --noconfirm jack2
    run_sudo pacman -S --needed --noconfirm pipewire-jack
  fi

  if caelestia_installed; then
    log "Caelestia/Hyprland configs detected, syncing with caelestia update"
    caelestia update
    return 0
  fi

  log "Installing Caelestia dots (this may take a while)"
  local helper
  helper="$(command -v yay >/dev/null && echo yay || echo paru)"
  caelestia install --noconfirm --aur-helper="$helper" --enable-components=zen --disable-components=firefox,vscode,vscodium,zed
}

ensure_hyprland_session() {
  local session="/usr/share/wayland-sessions/hyprland.desktop"
  if [[ -f "$session" ]]; then
    log "Hyprland session available at $session"
    return 0
  fi

  warn "Hyprland desktop session file not found; check hyprland package install"
}

install_caelestia_dots
ensure_hyprland_session
