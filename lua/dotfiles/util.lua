local uv = vim.uv
local M = {}

M.home = vim.env.HOME
M.config_home = vim.env.XDG_CONFIG_HOME or (M.home .. "/.config")
M.data_home = vim.env.XDG_DATA_HOME or (M.home .. "/.local/share")
M.root = vim.fs.normalize(debug.getinfo(1, "S").source:sub(2):match("(.*)/lua/dotfiles/"))

local function say(stream, colour, msg)
  stream:write(("\27[1;%sm[dotfiles]\27[0m %s\n"):format(colour, msg))
end

function M.log(msg)
  say(io.stdout, "34", msg)
end

function M.warn(msg)
  say(io.stderr, "33", msg)
end

function M.die(msg)
  say(io.stderr, "31", msg)
  os.exit(1)
end

function M.has(cmd)
  return vim.fn.executable(cmd) == 1
end

local function shell_join(cmd)
  return table.concat(vim.tbl_map(vim.fn.shellescape, cmd), " ")
end

-- Roda com o terminal do usuário (senha do sudo, barra do pacman, editor).
function M.run(cmd)
  local status = os.execute(shell_join(cmd))
  -- LuaJIT devolve o status cru do wait(); Lua 5.2+ devolve true/false.
  if type(status) == "number" then
    return status == 0
  end
  return status == true
end

function M.must(cmd)
  if not M.run(cmd) then
    M.die("Command failed: " .. shell_join(cmd))
  end
end

-- Roda calado. Devolve sucesso e a saída sem a quebra de linha final.
function M.capture(cmd, opts)
  local ok, res = pcall(function()
    return vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait()
  end)
  if not ok then
    return false, ""
  end
  return res.code == 0, vim.trim(res.stdout or ""), res
end

function M.check(cmd)
  return (M.capture(cmd))
end

function M.sudo(cmd)
  local password = vim.env.DOTFILES_SUDO_PASSWORD
  if not password or password == "" then
    return M.run(vim.list_extend({ "/usr/bin/sudo" }, cmd))
  end

  local ok, out, res = M.capture(vim.list_extend({ "/usr/bin/sudo", "-S", "-p", "" }, cmd), { stdin = password .. "\n" })
  io.stdout:write(out, out == "" and "" or "\n")
  if not ok and res and res.stderr then
    io.stderr:write(res.stderr)
  end
  return ok
end

-- Linhas de uma lista como packages/arch.txt, sem comentários nem linhas vazias.
function M.read_list(path)
  local items = {}
  local file = io.open(path, "r")
  if not file then
    return items
  end
  for line in file:lines() do
    line = vim.trim(line)
    if line ~= "" and not vim.startswith(line, "#") then
      table.insert(items, line)
    end
  end
  file:close()
  return items
end

function M.read(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local data = file:read("*a")
  file:close()
  return data
end

function M.write(path, data, mode)
  M.mkdirp(vim.fs.dirname(path))
  local file = assert(io.open(path, mode or "w"))
  file:write(data)
  file:close()
end

function M.append_line(path, line)
  M.write(path, line .. "\n", "a")
end

function M.expand(path)
  return (path:gsub("^~", M.home))
end

function M.short(path)
  if vim.startswith(path, M.home .. "/") then
    return "~" .. path:sub(#M.home + 1)
  end
  return path
end

function M.lstat(path)
  return uv.fs_lstat(path)
end

function M.exists(path)
  return uv.fs_stat(path) ~= nil
end

function M.is_dir(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

function M.is_link(path)
  local stat = uv.fs_lstat(path)
  return stat ~= nil and stat.type == "link"
end

function M.readlink(path)
  return uv.fs_readlink(path)
end

function M.mkdirp(path)
  vim.fn.mkdir(path, "p")
end

function M.same_file(a, b)
  local da, db = M.read(a), M.read(b)
  return da ~= nil and da == db
end

function M.copy(src, dst)
  M.mkdirp(vim.fs.dirname(dst))
  assert(uv.fs_copyfile(src, dst))
end

function M.timestamp()
  return os.date("%Y%m%d%H%M%S")
end

function M.tmpdir()
  return assert(uv.fs_mkdtemp(vim.fn.tempname() .. "-XXXXXX"))
end

function M.backup(path)
  local backup = ("%s.bak.%s"):format(path, M.timestamp())
  assert(os.rename(path, backup))
  return backup
end

-- Liga dst ao arquivo do repo. Um arquivo real em dst vira backup, para não perder edição local.
function M.link(src, dst)
  if not M.lstat(src) then
    return
  end
  if M.is_link(dst) and M.readlink(dst) == src then
    return
  end

  M.mkdirp(vim.fs.dirname(dst))
  if M.is_link(dst) then
    os.remove(dst)
  elseif M.lstat(dst) then
    M.log(("Backed up %s to %s"):format(M.short(dst), M.short(M.backup(dst))))
  end

  assert(uv.fs_symlink(src, dst))
  M.log("Linked " .. M.short(dst))
end

-- Pares {origem, destino} de um manifesto como links.txt, com caminhos absolutos.
function M.links(manifest)
  local pairs_ = {}
  for _, line in ipairs(M.read_list(manifest)) do
    local src, dst = line:match("^(%S+)%s+(%S+)$")
    if src then
      table.insert(pairs_, { M.root .. "/" .. src, M.expand(dst) })
    end
  end
  return pairs_
end

function M.pacman_installed(package)
  return M.check({ "pacman", "-Q", package })
end

function M.aur_helper()
  for _, helper in ipairs({ "yay", "paru" }) do
    if M.has(helper) then
      return helper
    end
  end
end

function M.distro_family()
  local release = M.read("/etc/os-release") or ""
  local ids = " " .. (release:match("\nID=\"?([^\"\n]*)") or release:match("^ID=\"?([^\"\n]*)") or "")
    .. " " .. (release:match("ID_LIKE=\"?([^\"\n]*)") or "") .. " "
  if ids:find(" arch ", 1, true) or ids:find(" cachyos ", 1, true) then
    return "arch"
  end
  return "unknown"
end

return M
