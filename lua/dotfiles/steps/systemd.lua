local u = require("dotfiles.util")

return {
  run = function()
    if not u.check({ "systemctl", "--user", "show-environment" }) then
      u.warn("Skipping user timers because the systemd user session is not running")
      return
    end
    u.must({ "systemctl", "--user", "daemon-reload" })
    u.must({ "systemctl", "--user", "enable", "--now", "dot-doctor.timer" })
    u.log("Enabled daily dot doctor check")
  end,
}
