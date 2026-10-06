#!/usr/bin/env bash
# Usado só pelo Bash que sobrou; o resto do bootstrap está em lua/dotfiles/util.lua.

log() {
  printf '\033[1;34m[dotfiles]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[dotfiles]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[dotfiles]\033[0m %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}
