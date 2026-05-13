#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

configure_git_aliases() {
  command_exists git || die "git is required"

  git config --global alias.c '!f() { git add . && git commit -m "$*"; }; f'
  log "Configured git alias: git c \"message\""
}

ensure_ssh_key() {
  local ssh_dir="$HOME/.ssh"
  local key_file="$ssh_dir/id_ed25519"
  local key_comment="${GIT_SSH_KEY_COMMENT:-$(whoami)@$(hostname)}"

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ -f "$key_file" ]]; then
    log "SSH key already exists: $key_file"
  else
    ssh-keygen -t ed25519 -C "$key_comment" -f "$key_file" -N ""
    log "Created SSH key: $key_file"
  fi

  chmod 600 "$key_file"
  chmod 644 "$key_file.pub"

  if command_exists ssh-add; then
    ssh-add "$key_file" >/dev/null 2>&1 || true
  fi
}

add_ssh_key_to_github() {
  command_exists gh || {
    warn "Skipping GitHub SSH key upload because gh is not installed"
    return 0
  }

  if ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI is not authenticated. Run: gh auth login"
    return 0
  fi

  local key_file="$HOME/.ssh/id_ed25519.pub"
  local title="${GITHUB_SSH_KEY_TITLE:-$(hostname)-dotfiles}"

  if gh ssh-key list 2>/dev/null | grep -Fq "$(cat "$key_file")"; then
    log "GitHub already has this SSH key"
    return 0
  fi

  gh ssh-key add "$key_file" --title "$title"
  log "Added SSH key to GitHub: $title"
}

configure_git_aliases
ensure_ssh_key
add_ssh_key_to_github

