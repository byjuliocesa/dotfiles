#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

if ! systemctl --user show-environment >/dev/null 2>&1; then
  warn "Skipping user timers because the systemd user session is not running"
  exit 0
fi

systemctl --user daemon-reload
systemctl --user enable --now dot-doctor.timer
log "Enabled daily dot doctor check"
