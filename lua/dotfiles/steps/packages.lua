local u = require("dotfiles.util")

local function install_aur_helper()
  if u.aur_helper() then
    u.log("AUR helper already installed")
    return
  end

  local build = u.tmpdir()
  u.log("Installing yay-bin from AUR")
  u.must({ "git", "clone", "https://aur.archlinux.org/yay-bin.git", build .. "/yay-bin" })
  local ok = u.run({ "makepkg", "-si", "--noconfirm", "--needed", "-D", build .. "/yay-bin" })
  vim.fn.delete(build, "rf")
  if not ok then
    u.die("Failed to build yay-bin")
  end
end

local function missing(list)
  return vim.tbl_filter(function(package)
    return not u.pacman_installed(package)
  end, u.read_list(u.root .. "/packages/" .. list .. ".txt"))
end

local function install_pacman_packages()
  local packages = missing("arch")
  if #packages == 0 then
    u.log("pacman packages already installed")
    return
  end

  u.log("Installing pacman packages: " .. table.concat(packages, " "))
  if not u.sudo(vim.list_extend({ "pacman", "-S", "--needed", "--noconfirm" }, packages)) then
    u.die("pacman failed")
  end
end

local function install_aur_packages()
  local packages = missing("aur")
  if #packages == 0 then
    u.log("AUR packages already installed")
    return
  end

  local helper = u.aur_helper()
  if not helper then
    u.warn("Skipping AUR packages because yay/paru is not installed yet")
    return
  end

  u.log(("Installing AUR packages with %s: %s"):format(helper, table.concat(packages, " ")))
  u.must(vim.list_extend({ helper, "-S", "--needed", "--noconfirm" }, packages))
end

-- Um pacote npm por linha. O binário tem o nome do pacote sem o escopo.
local function install_npm_globals(list)
  if not u.has("npm") then
    u.warn("Skipping npm packages because npm is not installed")
    return
  end

  for _, package in ipairs(u.read_list(list)) do
    local binary = package:gsub("^@[^/]+/", ""):gsub("@.*$", "")
    if u.has(binary) then
      u.log("npm package already available: " .. package)
    else
      u.log("Installing npm package: " .. package)
      u.sudo({ "npm", "install", "-g", package })
    end
  end
end

return {
  run = function()
    install_aur_helper()
    install_pacman_packages()
    install_aur_packages()
    install_npm_globals(u.root .. "/packages/npm-global.txt")
  end,
  install_npm_globals = install_npm_globals,
}
