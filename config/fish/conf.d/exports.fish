fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.opencode/bin"

if command -v go &> /dev/null
    set -gx GOPATH (go env GOPATH)
    fish_add_path "$GOPATH/bin"
end
