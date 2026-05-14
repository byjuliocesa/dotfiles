# kintiz dotfiles

Base pessoal para reconstruir o ambiente Linux depois de formatar ou trocar de distro.

## Como usar

```bash
cd ~/dotfiles
./install.sh
```

O script atual foca em sistemas compatíveis com Arch Linux, como CachyOS. Ele pode ser expandido aos poucos conforme novas configurações entrarem no ambiente.

Depois de autenticar a GitHub CLI, crie/suba o repositório:

```bash
gh auth login
./scripts/github-repo.sh dotfiles
```

O alias `git c "mensagem"` equivale a:

```bash
git add .
git commit -m "mensagem"
```

## Estrutura

- `install.sh`: ponto de entrada do bootstrap.
- `packages/arch.txt`: pacotes instalados via `pacman`.
- `packages/aur.txt`: pacotes instalados via `yay` ou `paru`.
- `packages/npm-global.txt`: pacotes globais instalados via `npm`.
- `codex/`: regras e ajustes locais do Codex restaurados pelo bootstrap.
- `assets/wallpapers/`: wallpapers versionados para restaurar em uma máquina nova.
- `skills/`: skills locais do Codex que devem ser restauradas pelo bootstrap.
- `scripts/`: funções e passos separados do bootstrap.

## Próximos itens bons para adicionar

- Configs do shell: `.zshrc`, `.bashrc`, aliases, prompt.
- Configs em `.config`: Hyprland, Caelestia, Zed, terminal, Git.
- Chaves e segredos: nunca versionar diretamente; documentar como restaurar.
- Instalação por distro: criar scripts separados para `arch`, `fedora`, `ubuntu`, etc.
