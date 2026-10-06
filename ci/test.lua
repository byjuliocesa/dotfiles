-- Roda num container archlinux com neovim e fish: nvim -l ci/test.lua
-- Não instala o ambiente inteiro: confere pacotes, sintaxe e se os links montam um HOME limpo.
local root = vim.fs.dirname(vim.fs.dirname(vim.uv.fs_realpath(arg[0])))
local failed = false

local function fail(msg)
  io.stderr:write(msg, "\n")
  failed = true
end

local function section(title)
  io.stdout:write("== ", title, "\n")
end

local function run(cmd, opts)
  return vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait()
end

local function list(path)
  local items = {}
  for line in io.lines(path) do
    line = vim.trim(line)
    if line ~= "" and not vim.startswith(line, "#") then
      table.insert(items, line)
    end
  end
  return items
end

local function files(pattern)
  return vim.fs.find(function(name)
    return name:match(pattern) ~= nil
  end, { path = root, type = "file", limit = math.huge })
end

section("packages/arch.txt exists in the repos")
for _, package in ipairs(list(root .. "/packages/arch.txt")) do
  if run({ "pacman", "-Si", package }).code ~= 0 then
    fail("not found: " .. package)
  end
end

section("lua syntax")
for _, file in ipairs(files("%.lua$")) do
  local _, err = loadfile(file)
  if err then
    fail(err)
  end
end

section("fish syntax")
for _, file in ipairs(files("%.fish$")) do
  local res = run({ "fish", "-n", file })
  if res.code ~= 0 then
    fail(res.stderr)
  end
end

section("links on a clean HOME")
local home = vim.fn.tempname()
vim.fn.mkdir(home, "p")
local env = { env = { HOME = home } }
for _, cmd in ipairs({ { "link" }, { "link" }, { "doctor", "links" } }) do
  local res = run(vim.list_extend({ root .. "/bin/dot" }, cmd), env)
  io.stdout:write(res.stdout, res.stderr)
  if res.code ~= 0 then
    fail("dot " .. table.concat(cmd, " ") .. " failed")
  end
end

os.exit(failed and 1 or 0)
