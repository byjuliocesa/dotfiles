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

run_sudo() {
  if [[ -n "${DOTFILES_SUDO_PASSWORD:-}" ]]; then
    printf '%s\n' "$DOTFILES_SUDO_PASSWORD" | /usr/bin/sudo -S -p '' "$@"
  else
    /usr/bin/sudo "$@"
  fi
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

# Liga dst ao arquivo do repo. Um arquivo real em dst vira backup, para não perder edição local.
link_path() {
  local src="$1" dst="$2"

  [[ -e "$src" ]] || return 0
  [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]] && return 0

  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup
    backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    log "Backed up $dst to $backup"
  fi

  ln -s "$src" "$dst"
  log "Linked $dst"
}

# Chama "$2 <origem> <destino>" para cada linha de um manifesto como links.txt.
each_link() {
  local manifest="$1" fn="$2" root src dst
  root="$(repo_root)"

  while read -r src dst; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    "$fn" "$root/$src" "${dst/#\~/$HOME}"
  done <"$manifest"
}
