local u = require("dotfiles.util")

local PLUGINS_DIR = u.config_home .. "/tmux/plugins"

-- Clona cada `set -g @plugin 'dono/nome'` do tmux.conf. O instalador do TPM
-- não serve aqui: ele só funciona com um servidor do tmux que já leu a config.
local function plugins()
  local list = {}
  for line in io.lines(u.root .. "/config/tmux/tmux.conf") do
    local repo = line:match("^%s*set%s+%-g%s+@plugin%s+['\"]([^'\"]+)['\"]")
    if repo then
      table.insert(list, repo)
    end
  end
  return list
end

return {
  run = function()
    if not u.has("tmux") then
      u.warn("Skipping tmux plugins because tmux is not installed")
      return
    end

    for _, repo in ipairs(plugins()) do
      local dir = PLUGINS_DIR .. "/" .. vim.fs.basename(repo)
      if u.is_dir(dir) then
        u.check({ "git", "-C", dir, "pull", "-q", "--ff-only" })
      else
        u.must({ "git", "clone", "-q", "--depth", "1", "https://github.com/" .. repo, dir })
        u.log("Installed tmux plugin " .. repo)
      end
    end
  end,
}
