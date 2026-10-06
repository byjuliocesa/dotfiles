local u = require("dotfiles.util")

local hypr_dir = u.config_home .. "/hypr"

local function caelestia_installed()
  return u.is_dir(hypr_dir) and #vim.fn.readdir(hypr_dir) > 0
end

local function install_dots()
  if not u.has("caelestia") then
    u.warn("Skipping Caelestia dots because caelestia-cli is not installed")
    return
  end

  if u.pacman_installed("jack2") then
    u.log("Removing jack2 to avoid conflict with pipewire-jack (common on KDE installs)")
    u.sudo({ "pacman", "-Rdd", "--noconfirm", "jack2" })
    u.sudo({ "pacman", "-S", "--needed", "--noconfirm", "pipewire-jack" })
  end

  if caelestia_installed() then
    u.log("Caelestia/Hyprland configs detected, syncing with caelestia update")
    u.must({ "caelestia", "update" })
    return
  end

  u.log("Installing Caelestia dots (this may take a while)")
  u.must({
    "caelestia", "install", "--noconfirm",
    "--aur-helper=" .. (u.aur_helper() or "yay"),
    "--enable-components=zen",
    "--disable-components=firefox,vscode,vscodium,zed",
  })
end

local function check_session()
  local session = "/usr/share/wayland-sessions/hyprland.desktop"
  if u.exists(session) then
    u.log("Hyprland session available at " .. session)
  else
    u.warn("Hyprland desktop session file not found; check hyprland package install")
  end
end

return {
  run = function()
    install_dots()
    check_session()
  end,
}
