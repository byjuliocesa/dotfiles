local u = require("dotfiles.util")

local SOURCE_LINE = '[[ -r "$HOME/.config/shell/aliases.sh" ]] && source "$HOME/.config/shell/aliases.sh"'

local function ensure_sources_aliases(rc_file)
  local rc = u.read(rc_file)
  if not rc then
    return
  end
  for line in rc:gmatch("[^\n]+") do
    if line == SOURCE_LINE then
      return
    end
  end
  u.write(rc_file, "\n" .. SOURCE_LINE .. "\n", "a")
  u.log(("Updated %s to source shell aliases"):format(vim.fs.basename(rc_file)))
end

local function install_fish_plugins()
  if not u.has("fish") then
    return
  end
  if not u.check({ "fish", "-c", "type -q fisher" }) then
    u.warn("Skipping fish plugins because fisher is not installed")
    return
  end
  u.log("Installing fish plugins from fish_plugins")
  u.check({ "fish", "-c", "fisher update" })
end

return {
  run = function()
    ensure_sources_aliases(u.home .. "/.bashrc")
    ensure_sources_aliases(u.home .. "/.zshrc")
    install_fish_plugins()
  end,
}
