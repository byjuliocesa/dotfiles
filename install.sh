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
      "$ROOT_DIR/scripts/caelestia.sh"
      ;;
    *)
      die "Unsupported distro for now. Add a new script under scripts/ for this distro."
      ;;
  esac

  "$ROOT_DIR/scripts/git.sh"
  "$ROOT_DIR/scripts/opencode.sh"
  "$ROOT_DIR/scripts/shell.sh"
  "$ROOT_DIR/scripts/lazyvim.sh"
  "$ROOT_DIR/scripts/codex.sh"
  "$ROOT_DIR/scripts/skills.sh"
  "$ROOT_DIR/scripts/wallpapers.sh"

  log "Bootstrap finished"
}

main "$@"
