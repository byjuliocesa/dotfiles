-- Usa as cores que o Caelestia gera a partir do wallpaper.
-- Sem o arquivo (máquina sem Caelestia), fica o tema padrão do LazyVim.
local theme_dir = vim.fn.expand("~/.local/state/caelestia/theme")
local theme_file = theme_dir .. "/nvim.lua"

if vim.fn.filereadable(theme_file) == 0 then
  return {}
end

local function apply()
  local ok, theme = pcall(dofile, theme_file)
  if not ok then
    return
  end
  vim.o.background = theme.mode == "light" and "light" or "dark"
  require("mini.base16").setup({ palette = theme.palette })
  vim.g.colors_name = "caelestia"
end

local function watch()
  -- O Caelestia troca o arquivo inteiro ao mudar o wallpaper, então vigia a pasta.
  local watcher = vim.uv.new_fs_event()
  watcher:start(theme_dir, {}, vim.schedule_wrap(function(err, filename)
    if not err and filename == "nvim.lua" then
      apply()
    end
  end))
end

return {
  { "nvim-mini/mini.base16", version = false, lazy = false, priority = 1000 },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        apply()
        watch()
      end,
    },
  },
}
