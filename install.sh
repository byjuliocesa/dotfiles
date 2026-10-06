#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib.sh
source "$ROOT_DIR/scripts/lib.sh"

main() {
  log "Starting Linux environment bootstrap"

  case "$(detect_distro_family)" in
    arch)
      "$ROOT_DIR/scripts/yay.sh"
      "$ROOT_DIR/scripts/arch.sh"
      ;;
    *)
      die "Unsupported distro for now. Add a new script under scripts/ for this distro."
      ;;
  esac

  # Links antes do Caelestia, para ele já encontrar os overrides no lugar.
  "$ROOT_DIR/scripts/links.sh"
  "$ROOT_DIR/scripts/caelestia.sh"
  "$ROOT_DIR/scripts/cursors.sh"

  if [[ -t 0 ]]; then
    "$ROOT_DIR/scripts/secrets.sh" restore
  else
    warn "Skipping secrets restore because there is no terminal to ask the password"
  fi

  "$ROOT_DIR/scripts/git.sh"
  "$ROOT_DIR/scripts/shell.sh"
  "$ROOT_DIR/scripts/lazyvim.sh"
  "$ROOT_DIR/scripts/wallpapers.sh"
  "$ROOT_DIR/scripts/fonts.sh"
  "$ROOT_DIR/scripts/systemd.sh"

  if [[ "${1:-}" == "--ai" ]]; then
    "$ROOT_DIR/scripts/ai.sh"
  fi

  log "Bootstrap finished"
}

main "$@"
