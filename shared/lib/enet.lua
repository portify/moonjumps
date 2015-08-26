local prev = rawget(_G, "enet")
local enet = require "enet"
rawset(_G, "enet", prev)
return enet
