local u = require("dotfiles.util")

local function install_opencode()
  if u.has("opencode") or u.exists(u.home .. "/.opencode/bin/opencode") then
    u.log("OpenCode already installed")
    return
  end
  if not u.has("curl") then
    u.die("curl is required to install OpenCode")
  end
  u.log("Installing OpenCode 2 via official install script")
  u.must({ "sh", "-c", "curl -fsSL https://opencode.ai/v2/install | bash" })
end

return {
  run = function()
    require("dotfiles.steps.packages").install_npm_globals(u.root .. "/ai/npm-global.txt")
    install_opencode()
    require("dotfiles.steps.links").run(u.root .. "/ai/links.txt")
  end,
}
