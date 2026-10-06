#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

sync_lazyvim_plugins() {
  command_exists nvim || {
    warn "Skipping LazyVim plugin sync because neovim is not installed"
    return 0
  }

  log "Bootstrapping LazyVim plugins (first run may take a while)"
  nvim --headless "+Lazy! sync" +qa
  log "LazyVim plugins synced"
}

sync_lazyvim_plugins
