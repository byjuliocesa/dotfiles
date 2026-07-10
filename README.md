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
- `shell/`: aliases e ajustes comuns para shells interativos.
- `config/fish/`: config do Fish (starship, direnv, zoxide, eza e abbrs).
- `assets/wallpapers/`: wallpapers versionados para restaurar em uma máquina nova.
- `skills/`: skills locais do Codex que devem ser restauradas pelo bootstrap.
- `scripts/`: funções e passos separados do bootstrap.

## Hyprland + Caelestia

O bootstrap instala Hyprland e os dots Caelestia via `caelestia-cli`.

- Pacotes base: `packages/arch.txt` e `packages/aur.txt`
- Overrides pessoais: `config/caelestia/hypr-vars.lua` e `config/caelestia/hypr-user.lua`
- Após instalar, escolha a sessão **Hyprland** no gerenciador de login (plasmalogin/SDDM)

## Próximos itens bons para adicionar

- Configs do shell: prompt e integrações maiores.
- Mais overrides em `config/caelestia/` e configs de Git.
- Chaves e segredos: nunca versionar diretamente; documentar como restaurar.
- Instalação por distro: criar scripts separados para `arch`, `fedora`, `ubuntu`, etc.
