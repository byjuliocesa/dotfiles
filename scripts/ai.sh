#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

AI_DIR="$ROOT_DIR/ai"
OPENCODE_BIN="$HOME/.opencode/bin/opencode"

install_npm_tools() {
  command_exists npm || {
    warn "Skipping AI npm packages because npm is not installed"
    return 0
  }

  local package binary
  while read -r package; do
    binary="${package##*/}"
    if command_exists "$binary"; then
      log "AI tool already available: $package"
      continue
    fi
    log "Installing AI tool: $package"
    run_sudo npm install -g "$package"
  done < <(grep -Ev '^\s*(#|$)' "$AI_DIR/npm-global.txt")
}

install_opencode() {
  if command_exists opencode || [[ -x "$OPENCODE_BIN" ]]; then
    log "OpenCode already installed"
    return 0
  fi

  command_exists curl || die "curl is required to install OpenCode"

  log "Installing OpenCode via official install script"
  curl -fsSL https://opencode.ai/install | bash
}

install_npm_tools
install_opencode
"$ROOT_DIR/scripts/links.sh" "$AI_DIR/links.txt"
