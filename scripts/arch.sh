#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib.sh
source "$ROOT_DIR/scripts/lib.sh"

install_pacman_packages() {
  local package_file="$ROOT_DIR/packages/arch.txt"
  local packages=()

  mapfile -t packages < <(grep -Ev '^\s*(#|$)' "$package_file")
  ((${#packages[@]} > 0)) || return 0

  local missing=()
  for package in "${packages[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done

  if ((${#missing[@]} == 0)); then
    log "pacman packages already installed"
    return 0
  fi

  log "Installing pacman packages: ${missing[*]}"
  run_sudo pacman -S --needed --noconfirm "${missing[@]}"
}

aur_helper() {
  if command_exists yay; then
    printf 'yay\n'
  elif command_exists paru; then
    printf 'paru\n'
  else
    return 1
  fi
}

install_aur_packages() {
  local package_file="$ROOT_DIR/packages/aur.txt"
  local packages=()

  mapfile -t packages < <(grep -Ev '^\s*(#|$)' "$package_file")
  ((${#packages[@]} > 0)) || return 0

  local helper
  helper="$(aur_helper)" || {
    warn "Skipping AUR packages because yay/paru is not installed yet"
    return 0
  }

  local missing=()
  for package in "${packages[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
      missing+=("$package")
    fi
  done

  if ((${#missing[@]} == 0)); then
    log "AUR/helper packages already installed"
    return 0
  fi

  log "Installing AUR/helper packages with $helper: ${missing[*]}"
  "$helper" -S --needed --noconfirm "${missing[@]}"
}

install_npm_globals() {
  local package_file="$ROOT_DIR/packages/npm-global.txt"
  local packages=()

  command_exists npm || {
    warn "Skipping npm global packages because npm is not installed"
    return 0
  }

  mapfile -t packages < <(grep -Ev '^\s*(#|$)' "$package_file")
  ((${#packages[@]} > 0)) || return 0

  for package in "${packages[@]}"; do
    local binary="${package##*/}"
    binary="${binary%@*}"

    if command_exists "$binary"; then
      log "npm global already available: $package"
      continue
    fi

    log "Installing npm global package: $package"
    run_sudo npm install -g "$package"
  done
}

install_pacman_packages
install_aur_packages
install_npm_globals
