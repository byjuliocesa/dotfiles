local u = require("dotfiles.util")

return {
  run = function()
    u.log("Bootstrapping LazyVim plugins (first run may take a while)")
    -- Outro nvim, com a config do usuário; este aqui roda sem plugins.
    u.must({ "nvim", "--headless", "+Lazy! sync", "+qa" })
    u.log("LazyVim plugins synced")
  end,
}
