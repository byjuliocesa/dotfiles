#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

# shellcheck disable=SC2016 # expande no shell do usuário, não aqui
SOURCE_LINE='[[ -r "$HOME/.config/shell/aliases.sh" ]] && source "$HOME/.config/shell/aliases.sh"'

ensure_shell_sources_aliases() {
  local rc_file="$1"

  [[ -f "$rc_file" ]] || return 0

  if grep -Fqx "$SOURCE_LINE" "$rc_file"; then
    return 0
  fi

  printf '\n%s\n' "$SOURCE_LINE" >>"$rc_file"
  log "Updated $(basename "$rc_file") to source shell aliases"
}

install_fish_plugins() {
  command_exists fish || return 0

  if ! fish -c 'type -q fisher'; then
    warn "Skipping fish plugins because fisher is not installed"
    return 0
  fi

  log "Installing fish plugins from fish_plugins"
  fish -c 'fisher update' >/dev/null
}

ensure_shell_sources_aliases "$HOME/.bashrc"
ensure_shell_sources_aliases "$HOME/.zshrc"
install_fish_plugins
