#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

OPENCODE_BIN="$HOME/.opencode/bin/opencode"

install_opencode() {
  if command_exists opencode; then
    log "OpenCode already available: $(opencode --version 2>/dev/null || true)"
    return 0
  fi

  if [[ -x "$OPENCODE_BIN" ]]; then
    log "OpenCode binary found at $OPENCODE_BIN"
    return 0
  fi

  command_exists curl || die "curl is required to install OpenCode"

  log "Installing OpenCode via official install script"
  curl -fsSL https://opencode.ai/install | bash
}

install_opencode
