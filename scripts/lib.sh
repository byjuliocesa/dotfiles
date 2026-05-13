#!/usr/bin/env bash

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

detect_distro_family() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
      *" arch "*|*" cachyos "*) printf 'arch\n' ;;
      *) printf 'unknown\n' ;;
    esac
    return
  fi

  printf 'unknown\n'
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

