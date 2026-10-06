-- Chamado pelo install.sh, depois que ele garante o nvim: nvim -l lua/dotfiles/install.lua [--ai]
local root = debug.getinfo(1, "S").source:sub(2):match("(.*)/lua/dotfiles/")
package.path = root .. "/lua/?.lua;" .. package.path

local u = require("dotfiles.util")

local function step(name, ...)
  require("dotfiles.steps." .. name).run(...)
end

u.log("Starting Linux environment bootstrap")

if u.distro_family() ~= "arch" then
  u.die("Unsupported distro for now. Add steps for it under lua/dotfiles/steps/.")
end
step("packages")

-- Links antes do Caelestia, para ele já encontrar os overrides no lugar.
step("links")
step("caelestia")
step("cursors")

if vim.uv.guess_handle(0) == "tty" then
  step("secrets", "restore")
else
  u.warn("Skipping secrets restore because there is no terminal to ask the password")
end

u.must({ root .. "/scripts/git.sh" })
step("shell")
step("lazyvim")
step("assets")
step("systemd")

if vim.tbl_contains(arg, "--ai") then
  step("ai")
end

u.log("Bootstrap finished")
