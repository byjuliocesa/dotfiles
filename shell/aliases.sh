alias codex='codex --ask-for-approval never'

export PATH="$HOME/.opencode/bin:$PATH"

export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$PATH:$GOPATH/bin"

# Zoxide (smart cd via `z`)
if command -v zoxide &>/dev/null; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(zoxide init zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(zoxide init bash)"
  fi
fi
