#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

REPO_NAME="${1:-dotfiles}"
VISIBILITY="${GITHUB_REPO_VISIBILITY:-private}"

cd "$ROOT_DIR"

command_exists git || die "git is required"
command_exists gh || die "gh is required. Install github-cli first."

if ! gh auth status >/dev/null 2>&1; then
  die "GitHub CLI is not authenticated. Run: gh auth login"
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -b main
fi

if gh repo view "$REPO_NAME" >/dev/null 2>&1; then
  log "GitHub repository already exists: $REPO_NAME"
else
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source "$ROOT_DIR" --remote origin
  log "Created GitHub repository: $REPO_NAME"
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  owner="$(gh api user --jq .login)"
  git remote add origin "git@github.com:$owner/$REPO_NAME.git"
fi

if ! ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1; then
  ssh-keyscan github.com >>"$HOME/.ssh/known_hosts"
  chmod 644 "$HOME/.ssh/known_hosts"
fi

git branch -M main
git c "initial dotfiles bootstrap" || true
git push -u origin main
