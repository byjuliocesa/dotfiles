-- Cursor: plugin hypr-dynamic-cursors (tilt + shake to find) e tema Hatsune Miku.
-- Fonte dos temas de cursor: GitHub (procurar por "cursor theme"; o atual é o
-- repositório em CURSOR_REPO abaixo).
-- O plugin é compilado manualmente porque hyprpm exige sudo e o commit precisa
-- bater com a versão exata do Hyprland instalada (pinos em hyprpm.toml).
local u = require("dotfiles.util")

local PLUGIN_REPO = "https://github.com/VirtCode/hypr-dynamic-cursors"
local PLUGIN_SRC = u.home .. "/.local/src/hypr-dynamic-cursors"
local PLUGIN_DIR = u.home .. "/.local/lib/hyprland-plugins"

local CURSOR_REPO = "https://github.com/supermariofps/hatsune-miku-windows-linux-cursors"
local CURSOR_THEME = "miku-cursor-linux"
local ICONS_DIR = u.data_home .. "/icons"

local function git(...)
  return vim.list_extend({ "git", "-C", PLUGIN_SRC }, { ... })
end

local function pinned_commit(hypr_commit)
  local ok, toml = u.capture(git("show", "origin/main:hyprpm.toml"))
  if not ok then
    return nil
  end
  for line in toml:gmatch("[^\n]+") do
    if line:find('"' .. hypr_commit .. '"', 1, true) then
      local commit = line:match('"(%x+)"%],')
      if commit and #commit == 40 then
        return commit
      end
    end
  end
end

local function install_dynamic_cursors()
  if not u.has("hyprctl") then
    u.warn("Skipping dynamic-cursors: Hyprland not installed")
    return
  end
  for _, dep in ipairs({ "git", "make", "g++", "pkg-config" }) do
    if not u.has(dep) then
      u.warn("Skipping dynamic-cursors: missing " .. dep)
      return
    end
  end

  if u.is_dir(PLUGIN_SRC .. "/.git") then
    u.must(git("fetch", "-q", "origin", "main"))
  else
    u.must({ "git", "clone", "-q", PLUGIN_REPO, PLUGIN_SRC })
  end

  local _, version = u.capture({ "hyprctl", "version" })
  local hypr_commit = version:match("commit (%x+)")
  if not hypr_commit then
    u.warn("Skipping dynamic-cursors: could not read Hyprland version (is Hyprland running?)")
    return
  end

  local plugin_commit = pinned_commit(hypr_commit)
  if not plugin_commit then
    plugin_commit = "origin/main"
    u.warn(("No pinned dynamic-cursors commit for Hyprland %s; building main (may fail)"):format(hypr_commit))
  end

  u.must(git("checkout", "-q", plugin_commit))
  local built, out = u.capture({ "make", "-C", PLUGIN_SRC, "clean", "all", "-j" .. #vim.uv.cpu_info() })
  if not built then
    io.stderr:write(out, "\n")
    u.die("Failed to build dynamic-cursors")
  end

  -- Nunca sobrescrever o .so no lugar: o Hyprland mantém o arquivo mapeado em
  -- memória e uma cópia por cima derruba o compositor. rename troca o inode atomicamente.
  local so, target = PLUGIN_SRC .. "/out/dynamic-cursors.so", PLUGIN_DIR .. "/dynamic-cursors.so"
  if u.same_file(so, target) then
    u.log("dynamic-cursors plugin already up to date")
    return
  end
  u.copy(so, target .. ".new")
  assert(os.rename(target .. ".new", target))
  u.log(("Installed dynamic-cursors plugin to %s (commit %s); takes effect on next Hyprland start")
    :format(u.short(PLUGIN_DIR), plugin_commit:sub(1, 7)))
end

local function install_miku_cursor()
  if u.is_dir(ICONS_DIR .. "/" .. CURSOR_THEME) then
    u.log("Cursor theme " .. CURSOR_THEME .. " already installed")
    return
  end

  local tmp = u.tmpdir()
  u.must({ "git", "clone", "-q", "--depth", "1", CURSOR_REPO, tmp .. "/repo" })
  u.mkdirp(ICONS_DIR)
  u.must({ "cp", "-r", tmp .. "/repo/" .. CURSOR_THEME, ICONS_DIR .. "/" })
  u.write(ICONS_DIR .. "/default/index.theme", ("[Icon Theme]\nInherits=%s\n"):format(CURSOR_THEME))
  vim.fn.delete(tmp, "rf")
  u.log("Installed cursor theme " .. CURSOR_THEME)
end

return {
  run = function()
    install_dynamic_cursors()
    install_miku_cursor()
  end,
}
