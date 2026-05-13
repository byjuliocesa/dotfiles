#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

SOURCE_DIR="$ROOT_DIR/skills"
TARGET_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

if [[ ! -d "$SOURCE_DIR" ]]; then
  exit 0
fi

mkdir -p "$TARGET_DIR"

for skill_dir in "$SOURCE_DIR"/*; do
  [[ -d "$skill_dir" ]] || continue

  target="$TARGET_DIR/$(basename "$skill_dir")"
  mkdir -p "$target"
  cp -R "$skill_dir"/. "$target"/
  log "Installed Codex skill: $(basename "$skill_dir")"
done

