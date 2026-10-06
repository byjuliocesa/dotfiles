-- Uma chave age por máquina decifra os segredos. A própria chave vai no repo
-- cifrada por senha, então uma máquina nova só precisa dessa senha.
local u = require("dotfiles.util")

local SECRETS_DIR = u.root .. "/secrets"
local KEY_FILE = u.config_home .. "/age/dotfiles.txt"
local ENCRYPTED_KEY = SECRETS_DIR .. "/key.age"
local RECIPIENT_FILE = SECRETS_DIR .. "/recipient.txt"
local MANIFEST = SECRETS_DIR .. "/manifest.txt"

local function require_age()
  if not u.has("age") then
    u.die("age is required (pacman -S age)")
  end
end

local function chmod600(path)
  vim.uv.fs_chmod(path, tonumber("600", 8))
end

local function init()
  require_age()
  if u.exists(ENCRYPTED_KEY) then
    u.die("Secrets already initialized: " .. ENCRYPTED_KEY)
  end

  u.mkdirp(vim.fs.dirname(KEY_FILE))
  u.must({ "age-keygen", "-o", KEY_FILE })
  chmod600(KEY_FILE)
  local _, recipient = u.capture({ "age-keygen", "-y", KEY_FILE })
  u.write(RECIPIENT_FILE, recipient .. "\n")

  u.log("Choose the password that will unlock the secrets on a new machine")
  u.must({ "age", "-p", "-o", ENCRYPTED_KEY, KEY_FILE })
  u.write(MANIFEST, "", "a")
  u.log("Secrets initialized. Add files with: dot secret add <file>")
end

local function ensure_key()
  if u.exists(KEY_FILE) then
    return
  end
  if not u.exists(ENCRYPTED_KEY) then
    u.die("No secrets key yet. Run: dot secret init")
  end

  u.mkdirp(vim.fs.dirname(KEY_FILE))
  u.log("Enter the secrets password")
  u.must({ "age", "-d", "-o", KEY_FILE, ENCRYPTED_KEY })
  chmod600(KEY_FILE)
end

local function entries()
  local list = {}
  for _, line in ipairs(u.read_list(MANIFEST)) do
    local name, dst = line:match("^(%S+)%s+(%S+)$")
    if name then
      table.insert(list, { name = name, dst = dst })
    end
  end
  return list
end

local function add(file)
  require_age()
  if not file then
    u.die("Usage: dot secret add <file>")
  end
  if not u.exists(RECIPIENT_FILE) then
    u.die("No secrets key yet. Run: dot secret init")
  end

  local abs = vim.uv.fs_realpath(file) or u.die("File not found: " .. file)
  if not vim.startswith(abs, u.home .. "/") then
    u.die("Only files inside $HOME can be secrets")
  end
  local rel = abs:sub(#u.home + 2)
  local name = rel:gsub("/", "__"):gsub("^%.", "")

  u.must({ "age", "-R", RECIPIENT_FILE, "-o", SECRETS_DIR .. "/" .. name .. ".age", abs })
  local line = ("%s ~/%s"):format(name, rel)
  if not vim.tbl_contains(u.read_list(MANIFEST), line) then
    u.append_line(MANIFEST, line)
  end
  u.log(("Encrypted ~/%s into secrets/%s.age"):format(rel, name))
end

local function restore()
  local list = entries()
  if #list == 0 then
    u.log("No secrets to restore")
    return
  end
  require_age()
  ensure_key()

  for _, entry in ipairs(list) do
    local dst = u.expand(entry.dst)
    local tmp = vim.fn.tempname()
    u.must({ "age", "-d", "-i", KEY_FILE, "-o", tmp, SECRETS_DIR .. "/" .. entry.name .. ".age" })
    chmod600(tmp)

    if u.same_file(tmp, dst) then
      os.remove(tmp)
    else
      if u.lstat(dst) then
        u.backup(dst)
      end
      -- tempname fica em /tmp, que pode ser outro disco; rename falharia.
      u.copy(tmp, dst)
      os.remove(tmp)
      chmod600(dst)
      u.log("Restored " .. u.short(dst))
    end
  end
end

return {
  run = function(cmd, ...)
    if cmd == "init" then
      init()
    elseif cmd == "add" then
      add(...)
    elseif cmd == "restore" then
      restore()
    else
      u.die("Usage: dot secret init | add <file> | restore")
    end
  end,
}
