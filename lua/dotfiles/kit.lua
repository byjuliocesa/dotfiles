-- Kits visuais: cada pasta em kits/<nome>/ guarda um kit.json com wallpaper, cores,
-- fontes, cursor e ícones. As fontes e cursores em si vêm de assets/ (passo "assets").
local u = require("dotfiles.util")

local KITS = u.root .. "/kits"
local DEFAULT_FILE = KITS .. "/default.txt"
local STATE = (vim.env.XDG_STATE_HOME or (u.home .. "/.local/state")) .. "/caelestia"
local SHELL_JSON = u.root .. "/config/caelestia/shell.json"
local CLI_JSON = u.root .. "/config/caelestia/cli.json"
local HYPR_VARS = u.root .. "/config/caelestia/hypr-vars.lua"
local FOOT_INI = u.root .. "/config/foot/foot.ini"
local FONTCONFIG = u.config_home .. "/fontconfig/fonts.conf"

local function read_json(path)
  return vim.json.decode(u.read(path))
end

-- jq mantém a formatação dos arquivos do repo, para o diff mostrar só o que mudou.
local function jq_edit(path, filter, args)
  local cmd = { "jq" }
  for name, value in pairs(args or {}) do
    vim.list_extend(cmd, { "--argjson", name, vim.json.encode(value) })
  end
  vim.list_extend(cmd, { filter, path })
  local ok, out = u.capture(cmd)
  if not ok then
    u.die("jq failed on " .. u.short(path))
  end
  u.write(path, out .. "\n")
end

local function gsettings(key, value)
  u.check({ "gsettings", "set", "org.gnome.desktop.interface", key, value })
end

local function gsettings_get(key)
  local _, out = u.capture({ "gsettings", "get", "org.gnome.desktop.interface", key })
  local value = (out or ""):gsub("^'", ""):gsub("'%s*$", "")
  return value
end

local function replace_line(path, pattern, line)
  local text = u.read(path)
  local new, n = text:gsub(pattern, line, 1)
  if n == 0 then
    u.warn(("Nothing to replace in %s"):format(u.short(path)))
  elseif new ~= text then
    u.write(path, new)
  end
end

local function kit_dir(name)
  local dir = KITS .. "/" .. name
  if not u.exists(dir .. "/kit.json") then
    u.die(("Kit '%s' not found. See: dot kit list"):format(name))
  end
  return dir
end

local function default_name()
  local list = u.exists(DEFAULT_FILE) and u.read_list(DEFAULT_FILE) or {}
  return list[1]
end

local function names()
  local list = {}
  for name, kind in vim.fs.dir(KITS) do
    if kind == "directory" and u.exists(KITS .. "/" .. name .. "/kit.json") then
      table.insert(list, name)
    end
  end
  table.sort(list)
  return list
end

local function write_fontconfig(fonts)
  u.mkdirp(vim.fs.dirname(FONTCONFIG))
  u.write(FONTCONFIG, ([[
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<!-- Gerado por "dot kit". Mudanças manuais somem no próximo kit. -->
<fontconfig>
  <alias><family>sans-serif</family><prefer><family>%s</family></prefer></alias>
  <alias><family>serif</family><prefer><family>%s</family></prefer></alias>
  <alias><family>monospace</family><prefer><family>%s</family><family>JetBrains Mono Nerd Font</family></prefer></alias>
</fontconfig>
]]):format(fonts.sans, fonts.serif, fonts.mono))
  u.check({ "fc-cache", "-f" })
end

local function apply(name)
  local dir = kit_dir(name)
  local kit = read_json(dir .. "/kit.json")

  -- Ícones antes das cores: o Caelestia reaplica o tema de ícones junto com as cores.
  -- Sem "icons", o Caelestia escolhe Papirus-Dark ou Papirus-Light pelo modo das cores.
  if kit.icons then
    jq_edit(CLI_JSON, ".theme.iconTheme = $v", { v = kit.icons })
    gsettings("icon-theme", kit.icons)
  else
    jq_edit(CLI_JSON, "del(.theme.iconTheme)")
  end

  -- O wallpaper vem antes das cores, porque trocar o wallpaper recalcula o esquema.
  if kit.wallpaper then
    u.must({ "caelestia", "wallpaper", "-f", dir .. "/" .. kit.wallpaper })
  end

  -- scheme.json pinta só o Caelestia. Terminal, GTK, Qt e bordas do Hyprland recebem
  -- as mesmas cores com "apps_colours" por cima: o shell pode ter fundo laranja e os apps não.
  if kit.scheme then
    u.copy(dir .. "/" .. kit.scheme, STATE .. "/scheme.json")
    u.must({
      "python3", "-c",
      "import json,sys; from caelestia.utils.theme import apply_colours; "
        .. "s=json.load(open(sys.argv[1])); c={**s['colours'], **json.loads(sys.argv[2])}; "
        .. "apply_colours(c, s['mode'])",
      STATE .. "/scheme.json",
      vim.json.encode(kit.apps_colours or vim.empty_dict()),
    })
  end

  if kit.fonts then
    local f = kit.fonts
    write_fontconfig(f)
    gsettings("font-name", ("%s %d"):format(f.sans, f.size or 10))
    gsettings("document-font-name", ("%s %d"):format(f.serif, (f.size or 10) + 1))
    gsettings("monospace-font-name", ("%s %d"):format(f.mono_ui or f.mono, f.size or 10))
    if f.terminal then
      replace_line(FOOT_INI, "\nfont=[^\n]*", "\nfont=" .. f.terminal)
    end
  end

  -- Logo da barra, do painel de cima e da tela de bloqueio. Sem "logo", volta ao do Caelestia.
  if kit.logo then
    jq_edit(SHELL_JSON, ".general.logo = $v", { v = u.short(dir .. "/" .. kit.logo) })
  else
    jq_edit(SHELL_JSON, "del(.general.logo)")
  end

  -- "shell_fonts": {} volta às fontes padrão do Caelestia.
  if kit.shell_fonts and next(kit.shell_fonts) == nil then
    jq_edit(SHELL_JSON, "del(.appearance.font)")
  elseif kit.shell_fonts then
    jq_edit(SHELL_JSON, ".appearance.font = $v", { v = kit.shell_fonts })
  end

  -- O Caelestia sempre grava adw-gtk3-dark; o kit corrige depois das cores.
  if kit.gtk_theme then
    gsettings("gtk-theme", kit.gtk_theme)
  end

  if kit.cursor then
    local c = kit.cursor
    replace_line(HYPR_VARS, 'cursorTheme = "[^"]*"', ('cursorTheme = "%s"'):format(c.theme))
    gsettings("cursor-theme", c.theme)
    gsettings("cursor-size", tostring(c.size or 24))
    u.check({ "hyprctl", "setcursor", c.theme, tostring(c.size or 24) })
  end

  u.log(("Kit '%s' applied. Apps already open pick up fonts and cursor when reopened."):format(name))
end

-- Guarda o visual atual como um kit novo (ou sobrescreve um existente).
local function save(name)
  if not name or not name:match("^[%w%-_]+$") then
    u.die("Usage: dot kit save <name>  (letters, numbers, - and _)")
  end
  local dir = KITS .. "/" .. name
  u.mkdirp(dir)

  -- apps_colours e logo não dá para ler do sistema; mantém os do kit, se já existir.
  local previous = u.exists(dir .. "/kit.json") and read_json(dir .. "/kit.json") or {}
  local kit = { apps_colours = previous.apps_colours, logo = previous.logo }

  local _, wall = u.capture({ "caelestia", "wallpaper" })
  wall = vim.trim(wall or "")
  if u.exists(wall) then
    kit.wallpaper = "wallpaper." .. (wall:match("%.(%w+)$") or "png")
    if not u.same_file(wall, dir .. "/" .. kit.wallpaper) then
      u.copy(wall, dir .. "/" .. kit.wallpaper)
    end
  end

  u.copy(STATE .. "/scheme.json", dir .. "/scheme.json")
  kit.scheme = "scheme.json"

  local function family(alias)
    local _, out = u.capture({ "fc-match", "-f", "%{family[0]}", alias })
    return vim.trim(out or "")
  end
  kit.fonts = {
    sans = family("sans-serif"),
    serif = family("serif"),
    mono = family("monospace"),
    size = tonumber(gsettings_get("font-name"):match("(%d+)$")) or 10,
    terminal = u.read(FOOT_INI):match("\nfont=([^\n]*)"),
  }
  kit.shell_fonts = (read_json(SHELL_JSON).appearance or {}).font

  kit.gtk_theme = gsettings_get("gtk-theme")
  local mono_ui = gsettings_get("monospace-font-name"):match("^(.-)%s+%d+$")
  if mono_ui and mono_ui ~= kit.fonts.mono then
    kit.fonts.mono_ui = mono_ui
  end

  kit.cursor = { theme = gsettings_get("cursor-theme"), size = tonumber(gsettings_get("cursor-size")) or 24 }
  kit.icons = gsettings_get("icon-theme")

  u.write(dir .. "/kit.json", vim.json.encode(kit, { indent = "  ", sort_keys = true }) .. "\n")
  u.log(("Saved kit '%s' in %s"):format(name, u.short(dir)))
end

local function list()
  local default = default_name()
  for _, name in ipairs(names()) do
    io.stdout:write(name .. (name == default and "  (default)" or "") .. "\n")
  end
end

local M = {}

function M.run(cmd, arg)
  if cmd == nil then
    local name = default_name() or u.die("No default kit. Set one with: dot kit set-default <name>")
    apply(name)
  elseif cmd == "list" then
    list()
  elseif cmd == "save" then
    save(arg)
  elseif cmd == "set-default" then
    if not arg then
      io.stdout:write((default_name() or "none") .. "\n")
    else
      kit_dir(arg)
      u.write(DEFAULT_FILE, arg .. "\n")
      u.log(("Default kit is now '%s'"):format(arg))
    end
  else
    apply(cmd)
  end
end

return M
