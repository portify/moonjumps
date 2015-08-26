local args = require "shared.lib.args"

if args.flag "server" then
  require "main-server"
else
  require "main-client"
end
