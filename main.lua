local args = require "shared.lib.args"

if args.flag "server" then
  require "server.main"
else
  require "client.main"
end
