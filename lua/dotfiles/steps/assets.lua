-- Wallpapers vêm de https://wallhaven.cc (os "wallhaven-xxxxxx.jpg").
-- Fontes vêm de https://www.programmingfonts.org (preview de fontes de código;
-- cada uma linka o download oficial). CommitMono vem de https://commitmono.com.
-- Anthropic Sans/Serif/Mono e o cursor Claude: origem em assets/fonts/anthropic/SOURCE.md e assets/cursors/SOURCE-*.md.
local u = require("dotfiles.util")

local function files(dir)
  return vim.fs.find(function()
    return true
  end, { path = dir, type = "file", limit = math.huge })
end

local function install_wallpapers()
  local target_dir = (vim.env.XDG_PICTURES_DIR or (u.home .. "/Imagens")) .. "/Wallpapers"
  local wallpapers = files(u.root .. "/assets/wallpapers")
  if #wallpapers == 0 then
    u.warn("No wallpapers found in assets/wallpapers")
    return
  end

  for _, wallpaper in ipairs(wallpapers) do
    local target = target_dir .. "/" .. vim.fs.basename(wallpaper)
    if u.exists(target) then
      u.log("Wallpaper already exists: " .. u.short(target))
    else
      u.copy(wallpaper, target)
      u.log("Copied wallpaper: " .. u.short(target))
    end
  end
end

local function install_fonts()
  local fonts = vim.tbl_filter(function(path)
    return path:match("%.otf$") or path:match("%.ttf$")
  end, files(u.root .. "/assets/fonts"))
  if #fonts == 0 then
    u.warn("No fonts found in assets/fonts")
    return
  end

  local changed = false
  for _, font in ipairs(fonts) do
    local family = vim.fs.basename(vim.fs.dirname(font))
    local target = ("%s/fonts/%s/%s"):format(u.data_home, family, vim.fs.basename(font))
    if not u.same_file(font, target) then
      u.copy(font, target)
      changed = true
      u.log("Installed font: " .. u.short(target))
    end
  end

  if not changed then
    u.log("Fonts already up to date")
  elseif u.has("fc-cache") then
    u.check({ "fc-cache", "-f" })
    u.log("Font cache refreshed")
  end
end

-- Cada assets/cursors/<tema>.tar.xz traz a pasta <tema>/ na raiz.
local function install_cursors()
  local archives = vim.tbl_filter(function(path)
    return path:match("%.tar%.xz$")
  end, files(u.root .. "/assets/cursors"))

  local icons = u.data_home .. "/icons"
  for _, archive in ipairs(archives) do
    local theme = vim.fs.basename(archive):gsub("%.tar%.xz$", "")
    local target = icons .. "/" .. theme
    if u.exists(target .. "/index.theme") then
      u.log("Cursor already installed: " .. u.short(target))
    else
      vim.fn.mkdir(icons, "p")
      u.check({ "tar", "-xJf", archive, "-C", icons })
      u.log("Installed cursor: " .. u.short(target))
    end
  end
end

return {
  run = function()
    install_wallpapers()
    install_fonts()
    install_cursors()
  end,
}
