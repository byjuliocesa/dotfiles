# kintiz dotfiles

Base pessoal para reconstruir o ambiente Linux depois de formatar ou trocar de distro.

## Como usar

```bash
cd ~/dotfiles
./install.sh        # ambiente base
./install.sh --ai   # base + ferramentas de IA (Codex, OpenCode, skills)
```

Cada linha de `links.txt` liga um arquivo do repo ao lugar dele em `~`. Editar um é editar o outro. Se já existir um arquivo no destino, ele vira `<arquivo>.bak.<data>` antes do link.

O script atual foca em sistemas compatíveis com Arch Linux, como CachyOS.

## Dia a dia: comando `dot`

| Comando | O que faz |
|---|---|
| `dot sync` | puxa o repo e refaz os links |
| `dot save "mensagem"` | commita tudo e faz push |
| `dot edit fish` | abre no editor a config que casa com o nome |
| `dot doctor` | lista links quebrados ou faltando e pacotes não instalados |
| `dot secret add <arquivo>` | guarda um arquivo cifrado no repo (veja `secrets/README.md`) |

Para versionar uma config nova: mova o arquivo para `config/`, adicione uma linha em `links.txt` e rode `dot sync`.

## Estrutura

- `install.sh`: ponto de entrada do bootstrap.
- `links.txt`: o que vai para onde em `~`.
- `bin/dot`: o comando do dia a dia, ligado em `~/.local/bin/dot`.
- `packages/`: listas de pacotes para `pacman`, AUR e `npm`.
- `config/`: fish (com `conf.d/` por assunto e plugins via fisher), foot, tmux, nvim (LazyVim), git, starship e Caelestia.
- `shell/`: aliases para bash e zsh.
- `secrets/`: arquivos cifrados com `age`, restaurados pelo install.
- `ai/`: pacotes, regras e skills de IA, com o próprio `links.txt`. Só instala com `--ai`.
- `assets/`: wallpapers e fontes.
- `scripts/`: um passo do bootstrap por arquivo.
- `ci/` e `.github/workflows/`: a cada push, roda `shellcheck`, confere se os pacotes existem e monta os links num HOME limpo dentro de um container Arch.

## Hyprland + Caelestia

O bootstrap instala Hyprland e os dots Caelestia via `caelestia-cli`.

- Pacotes base: `packages/arch.txt` e `packages/aur.txt`
- Overrides pessoais: `config/caelestia/hypr-vars.lua`, `hypr-user.lua` e `shell.json`
- Layout de monitores fica fora do repo, porque muda por máquina. `hypr-user.lua` só carrega se existir.
- Após instalar, escolha a sessão **Hyprland** no gerenciador de login (plasmalogin/SDDM)
- Cursor: `scripts/cursors.sh` compila o plugin [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors) (tilt + shake to find) para a versão exata do Hyprland e instala o tema [Hatsune Miku](https://github.com/supermariofps/hatsune-miku-windows-linux-cursors). Rode de novo após atualizar o Hyprland.

## De onde vêm os assets

Referência para trocar ou baixar novos:

| Tipo | Onde pego | Onde fica no repo |
|---|---|---|
| Wallpapers | https://wallhaven.cc | `assets/wallpapers/` (`scripts/wallpapers.sh`) |
| Fontes de código | https://www.programmingfonts.org (atual: [CommitMono](https://commitmono.com)) | `assets/fonts/<Familia>/` (`scripts/fonts.sh`) |
| Cursor | GitHub (atual: [hatsune-miku-windows-linux-cursors](https://github.com/supermariofps/hatsune-miku-windows-linux-cursors)) | `scripts/cursors.sh` |
| Plugin de cursor | [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors) | `scripts/cursors.sh` |

## Próximos itens bons para adicionar

- Instalação por distro: criar scripts separados para `arch`, `fedora`, `ubuntu`, etc.
