#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

# A config versionada fica em ~/.config/git/config. Um ~/.gitconfig real
# teria prioridade e receberia as escritas do `git config --global`.
retire_legacy_gitconfig() {
  local legacy="$HOME/.gitconfig"

  [[ -f "$legacy" && ! -L "$legacy" ]] || return 0

  local backup
  backup="$legacy.bak.$(date +%Y%m%d%H%M%S)"
  mv "$legacy" "$backup"
  log "Moved $legacy to $backup; git now reads ~/.config/git/config"
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

ensure_github_known_host() {
  local known_hosts="$HOME/.ssh/known_hosts"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if ssh-keygen -F github.com -f "$known_hosts" >/dev/null 2>&1; then
    log "github.com already exists in known_hosts"
    return 0
  fi

  if command_exists ssh-keyscan; then
    ssh-keyscan github.com >>"$known_hosts"
    chmod 644 "$known_hosts"
    log "Added github.com to known_hosts"
  else
    warn "Skipping github.com known_hosts setup because ssh-keyscan is not installed"
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

retire_legacy_gitconfig
ensure_ssh_key
ensure_github_known_host
add_ssh_key_to_github
