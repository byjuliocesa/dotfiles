local u = require("dotfiles.util")

local USAGE = [[
Usage: dot <command>

  sync              pull the repo and relink every config
  link              relink every config without pulling
  save "msg"        commit everything and push
  edit <name>       open the config whose path matches <name>
  doctor [links]    report broken links and package drift
  pkg add <pkg>     install a package and record it in packages/
  pkg drift         list installed packages missing from packages/
  pkg ignore <pkg>  stop reporting a package as drift
  secret ...        init | add <file> | restore
]]

local function manifests()
  local list = { u.root .. "/links.txt" }
  if u.is_dir(u.home .. "/.codex") then
    table.insert(list, u.root .. "/ai/links.txt")
  end
  return list
end

local function git(...)
  return vim.list_extend({ "git", "-C", u.root }, { ... })
end

local function sync()
  u.must(git("pull", "--rebase", "--autostash"))
  for _, manifest in ipairs(manifests()) do
    require("dotfiles.steps.links").run(manifest)
  end
end

local function save(...)
  local message = table.concat({ ... }, " ")
  if message == "" then
    u.die('Usage: dot save "message"')
  end
  u.must(git("add", "-A"))
  u.must(git("commit", "-m", message))
  u.must(git("push"))
end

local function edit(name)
  if not name then
    u.die("Usage: dot edit <name>")
  end

  local matches = {}
  for _, line in ipairs(u.read_list(u.root .. "/links.txt")) do
    local src = line:match("^(%S+)")
    if src:lower():find(name:lower(), 1, true) then
      table.insert(matches, src)
    end
  end

  local pick = matches[1]
  if #matches == 0 then
    u.die(("No config matches '%s'"):format(name))
  elseif #matches > 1 then
    if not u.has("fzf") then
      u.die("Several matches: " .. table.concat(matches, " "))
    end
    -- fzf desenha em /dev/tty, então dá para capturar só a escolha.
    local ok
    ok, pick = u.capture({ "fzf", "--prompt", "dot edit> " }, { stdin = table.concat(matches, "\n") })
    if not ok then
      return
    end
  end

  local editor = vim.env.EDITOR or "nvim"
  os.execute(editor .. " " .. vim.fn.shellescape(u.root .. "/" .. pick))
end

local function listed_packages()
  local set = {}
  for _, list in ipairs({ "arch", "aur", "ignore" }) do
    for _, package in ipairs(u.read_list(("%s/packages/%s.txt"):format(u.root, list))) do
      set[package] = true
    end
  end
  return set
end

local function drift_packages()
  local listed = listed_packages()
  local _, out = u.capture({ "pacman", "-Qqe" })
  local drift = {}
  for package in out:gmatch("%S+") do
    if not listed[package] then
      table.insert(drift, package)
    end
  end
  table.sort(drift)
  return drift
end

local function remove_line(path, value)
  local kept = vim.tbl_filter(function(line)
    return line ~= value
  end, vim.split(u.read(path) or "", "\n", { trimempty = true }))
  u.write(path, table.concat(kept, "\n") .. "\n")
end

local function pkg_add(packages)
  if #packages == 0 then
    u.die("Usage: dot pkg add <package>...")
  end

  for _, package in ipairs(packages) do
    local list
    if u.check({ "pacman", "-Si", package }) then
      if not u.sudo({ "pacman", "-S", "--needed", "--noconfirm", package }) then
        u.die("pacman failed for " .. package)
      end
      list = "arch"
    else
      local helper = u.aur_helper() or u.die(package .. " is not in pacman and no AUR helper is installed")
      u.must({ helper, "-S", "--needed", package })
      list = "aur"
    end

    remove_line(u.root .. "/packages/ignore.txt", package)
    if not listed_packages()[package] then
      u.append_line(("%s/packages/%s.txt"):format(u.root, list), package)
      u.log(("Recorded %s in packages/%s.txt"):format(package, list))
    end
  end
end

local function pkg(cmd, ...)
  local rest = { ... }
  if cmd == "add" then
    pkg_add(rest)
  elseif cmd == "drift" then
    for _, package in ipairs(drift_packages()) do
      io.stdout:write(package, "\n")
    end
  elseif cmd == "ignore" then
    if #rest == 0 then
      u.die("Usage: dot pkg ignore <package>...")
    end
    for _, package in ipairs(rest) do
      u.append_line(u.root .. "/packages/ignore.txt", package)
    end
  else
    u.die("Usage: dot pkg add | drift | ignore")
  end
end

local function link_problem(src, dst)
  local short = u.short(dst)
  if u.is_link(dst) and u.readlink(dst) == src then
    if u.exists(dst) then
      return nil
    end
    return "broken: " .. short .. " points to a missing file"
  elseif u.is_link(dst) then
    return ("foreign: %s points to %s"):format(short, u.readlink(dst))
  elseif u.lstat(dst) then
    return "copy: " .. short .. " is a real file, not a link (run: dot sync)"
  end
  return "missing: " .. short .. " (run: dot sync)"
end

local function doctor(scope)
  local issues = 0
  local function report(msg)
    u.warn(msg)
    issues = issues + 1
  end

  for _, manifest in ipairs(manifests()) do
    for _, pair in ipairs(u.links(manifest)) do
      local problem = link_problem(pair[1], pair[2])
      if problem then
        report(problem)
      end
    end
  end

  if scope ~= "links" and u.has("pacman") then
    for _, list in ipairs({ "arch", "aur" }) do
      for _, package in ipairs(u.read_list(("%s/packages/%s.txt"):format(u.root, list))) do
        if not u.pacman_installed(package) then
          report("package not installed: " .. package)
        end
      end
    end

    local drift = #drift_packages()
    if drift > 0 then
      report(("%d package(s) installed but not in packages/ (run: dot pkg drift)"):format(drift))
    end
  end

  if issues == 0 then
    u.log("Everything in place")
  else
    u.die(("%d issue(s) found"):format(issues))
  end
end

local M = {}

function M.main(argv)
  local cmd = argv[1]
  local rest = { unpack(argv, 2) }

  if cmd == "sync" then
    sync()
  elseif cmd == "link" then
    for _, manifest in ipairs(manifests()) do
      require("dotfiles.steps.links").run(manifest)
    end
  elseif cmd == "save" then
    save(unpack(rest))
  elseif cmd == "edit" then
    edit(rest[1])
  elseif cmd == "doctor" then
    doctor(rest[1])
  elseif cmd == "pkg" then
    pkg(unpack(rest))
  elseif cmd == "secret" then
    require("dotfiles.steps.secrets").run(unpack(rest))
  elseif cmd == nil or cmd == "help" or cmd == "-h" or cmd == "--help" then
    io.stdout:write(USAGE)
  else
    io.stderr:write(USAGE)
    os.exit(1)
  end
end

return M
