#!/usr/bin/env bash
# Roda dentro de um container archlinux como root. Não instala o ambiente
# inteiro: confere pacotes, sintaxe e se os links montam um HOME limpo.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# steam vem do multilib, que a imagem do container não habilita.
grep -q '^\[multilib\]' /etc/pacman.conf ||
  printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >>/etc/pacman.conf
pacman -Syu --noconfirm --needed fish >/dev/null

echo "== packages/arch.txt exists in the repos"
missing=0
while read -r package; do
  pacman -Si "$package" >/dev/null 2>&1 || {
    echo "not found: $package"
    missing=1
  }
done < <(grep -Ev '^\s*(#|$)' "$ROOT_DIR/packages/arch.txt")
((missing == 0))

echo "== fish syntax"
find "$ROOT_DIR/config/fish" -name '*.fish' -print0 | xargs -0 -n1 fish -n

echo "== links on a clean HOME"
export HOME
HOME="$(mktemp -d)"
"$ROOT_DIR/scripts/links.sh"
"$ROOT_DIR/scripts/links.sh"
"$ROOT_DIR/bin/dot" doctor links
