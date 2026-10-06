#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

# Uma chave age por máquina decifra os segredos. A própria chave vai no repo
# cifrada por senha, então uma máquina nova só precisa dessa senha.
SECRETS_DIR="$ROOT_DIR/secrets"
KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/age/dotfiles.txt"
ENCRYPTED_KEY="$SECRETS_DIR/key.age"
RECIPIENT_FILE="$SECRETS_DIR/recipient.txt"
MANIFEST="$SECRETS_DIR/manifest.txt"

require_age() {
  command_exists age || die "age is required (pacman -S age)"
}

cmd_init() {
  require_age
  [[ -f "$ENCRYPTED_KEY" ]] && die "Secrets already initialized: $ENCRYPTED_KEY"

  mkdir -p "$(dirname "$KEY_FILE")"
  (umask 077 && age-keygen -o "$KEY_FILE" 2>/dev/null)
  age-keygen -y "$KEY_FILE" >"$RECIPIENT_FILE"

  log "Choose the password that will unlock the secrets on a new machine"
  age -p -o "$ENCRYPTED_KEY" "$KEY_FILE"
  touch "$MANIFEST"
  log "Secrets initialized. Add files with: dot secret add <file>"
}

ensure_key() {
  [[ -f "$KEY_FILE" ]] && return 0
  [[ -f "$ENCRYPTED_KEY" ]] || die "No secrets key yet. Run: dot secret init"

  mkdir -p "$(dirname "$KEY_FILE")"
  log "Enter the secrets password"
  (umask 077 && age -d -o "$KEY_FILE" "$ENCRYPTED_KEY")
}

cmd_add() {
  require_age
  [[ $# -eq 1 ]] || die "Usage: dot secret add <file>"
  [[ -f "$RECIPIENT_FILE" ]] || die "No secrets key yet. Run: dot secret init"

  local abs rel name
  abs="$(realpath "$1")"
  rel="${abs#"$HOME"/}"
  [[ "$rel" != "$abs" ]] || die "Only files inside \$HOME can be secrets"
  name="${rel//\//__}"
  name="${name#.}"

  age -R "$RECIPIENT_FILE" -o "$SECRETS_DIR/$name.age" "$abs"
  grep -qx "$name ~/$rel" "$MANIFEST" 2>/dev/null || printf '%s ~/%s\n' "$name" "$rel" >>"$MANIFEST"
  log "Encrypted ~/$rel into secrets/$name.age"
}

cmd_restore() {
  [[ -s "$MANIFEST" ]] || {
    log "No secrets to restore"
    return 0
  }
  require_age
  ensure_key

  local name dst tmp
  while read -r name dst; do
    [[ -z "$name" ]] && continue
    dst="${dst/#\~/$HOME}"
    tmp="$(mktemp)"
    age -d -i "$KEY_FILE" -o "$tmp" "$SECRETS_DIR/$name.age"

    if [[ -f "$dst" ]] && cmp -s "$tmp" "$dst"; then
      rm "$tmp"
      continue
    fi
    if [[ -e "$dst" ]]; then
      mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    fi

    mkdir -p "$(dirname "$dst")"
    mv "$tmp" "$dst"
    chmod 600 "$dst"
    log "Restored ${dst/#"$HOME"/\~}"
  done <"$MANIFEST"
}

case "${1:-}" in
  init) cmd_init ;;
  add) shift; cmd_add "$@" ;;
  restore) cmd_restore ;;
  *) die "Usage: dot secret init | add <file> | restore" ;;
esac
