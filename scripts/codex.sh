#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

SOURCE_DIR="$ROOT_DIR/codex"
TARGET_DIR="${CODEX_HOME:-$HOME/.codex}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  exit 0
fi

mkdir -p "$TARGET_DIR/rules"

if [[ -f "$SOURCE_DIR/rules/default.rules" ]]; then
  cp "$SOURCE_DIR/rules/default.rules" "$TARGET_DIR/rules/default.rules"
  log "Installed Codex approval rules"
fi
