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
| `dot doctor` | lista links quebrados ou faltando e pacotes fora das listas |
| `dot pkg add <pacote>` | instala (pacman ou AUR) e já anota em `packages/` |
| `dot pkg drift` | mostra o que está instalado mas não está em `packages/` |
| `dot pkg ignore <pacote>` | para de cobrar um pacote (vai para `packages/ignore.txt`) |
| `dot secret add <arquivo>` | guarda um arquivo cifrado no repo (veja `secrets/README.md`) |

Um timer do systemd roda `dot doctor` uma vez por dia e manda uma notificação se algo saiu do lugar.

Para versionar uma config nova: mova o arquivo para `config/`, adicione uma linha em `links.txt` e rode `dot sync`.

## Estrutura

- `install.sh`: ponto de entrada do bootstrap.
- `links.txt`: o que vai para onde em `~`.
- `bin/dot`: o comando do dia a dia, ligado em `~/.local/bin/dot`.
- `packages/`: listas de pacotes para `pacman`, AUR e `npm`.
- `config/`: fish (com `conf.d/` por assunto e plugins via fisher), foot, tmux, nvim (LazyVim), git, lazygit, yazi, Caelestia e o timer do systemd.
- `shell/`: aliases para bash e zsh.
- `secrets/`: arquivos cifrados com `age`, restaurados pelo install.
- `ai/`: pacotes, regras e skills de IA, com o próprio `links.txt`. Só instala com `--ai`.
- `assets/`: wallpapers e fontes.
- `lua/dotfiles/`: o bootstrap e o `dot`, em Lua. Cada passo do install é um arquivo em `steps/`. Rodam com `nvim -l`, sem carregar plugins.
- `ci/` e `.github/workflows/`: a cada push, roda `shellcheck` no Bash que sobrou e, num container Arch, confere pacotes, sintaxe de Lua e fish e monta os links num HOME limpo.

## Hyprland + Caelestia

O bootstrap instala Hyprland e os dots Caelestia via `caelestia-cli`.

- Pacotes base: `packages/arch.txt` e `packages/aur.txt`
- Overrides pessoais: `config/caelestia/hypr-vars.lua`, `hypr-user.lua` e `shell.json`
- Cores: o Caelestia gera a paleta do wallpaper. O nvim usa o tema oficial dele (`config/nvim/colors/caelestia.lua`), que troca de cor na hora. O tmux usa `config/caelestia/templates/tmux.conf` e recarrega pelo `postHook` em `cli.json`. Starship, lazygit e yazi usam as cores do terminal, que o Caelestia já pinta.
- O `starship.toml` é do Caelestia: o `caelestia update` sobrescreve, por isso ele não fica no repo.
- Layout de monitores fica fora do repo, porque muda por máquina. `hypr-user.lua` só carrega se existir.
- Após instalar, escolha a sessão **Hyprland** no gerenciador de login (plasmalogin/SDDM)
- Cursor: `lua/dotfiles/steps/cursors.lua` compila o plugin [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors) (tilt + shake to find) para a versão exata do Hyprland e instala o tema [Hatsune Miku](https://github.com/supermariofps/hatsune-miku-windows-linux-cursors). Rode de novo após atualizar o Hyprland.

## De onde vêm os assets

Referência para trocar ou baixar novos:

| Tipo | Onde pego | Onde fica no repo |
|---|---|---|
| Wallpapers | https://wallhaven.cc | `assets/wallpapers/` (`lua/dotfiles/steps/assets.lua`) |
| Fontes de código | https://www.programmingfonts.org (atual: [CommitMono](https://commitmono.com)) | `assets/fonts/<Familia>/` (`lua/dotfiles/steps/assets.lua`) |
| Cursor | GitHub (atual: [hatsune-miku-windows-linux-cursors](https://github.com/supermariofps/hatsune-miku-windows-linux-cursors)) | `lua/dotfiles/steps/cursors.lua` |
| Plugin de cursor | [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors) | `lua/dotfiles/steps/cursors.lua` |

## Próximos itens bons para adicionar

- Instalação por distro: criar scripts separados para `arch`, `fedora`, `ubuntu`, etc.
