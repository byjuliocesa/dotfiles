local u = require("dotfiles.util")

return {
  run = function(manifest)
    for _, pair in ipairs(u.links(manifest or (u.root .. "/links.txt"))) do
      u.link(pair[1], pair[2])
    end
  end,
}
