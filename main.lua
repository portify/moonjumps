if arg[2] == "server" or arg[3] == "server" then
  require "main-server"
else
  require "main-client"
end
