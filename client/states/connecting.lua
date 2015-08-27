local enet = require "enet"
local constants = require "shared.constants"

local state = require "client.lib.state"
local game = require "client.states.game"

local index = {}

function index:enter()
  love.graphics.setFont(love.graphics.newFont("bloat/SourceCodePro-Regular.ttf", 12))

  self.failed = false
  self.status = "Connecting to " .. self.address

  print("Connecting to " .. self.address)
  self.host = enet.host_create(nil, 1, constants.channels, 0, 0)

  if self.host == nil then
    return self:fail("host_create returned nil")
  end

  -- self.host = require("shared.lib.unfair")(self.host)
  self.peer = self.host:connect(self.address, constants.channels, 0)

  if self.peer == nil then
    return self:fail("host.connect returned nil")
  end
end

function index:fail(message)
  print("Failed: " .. message)

  self.failed = true
  self.status = message

  self.host = nil
  self.peer = nil
end

function index:update(dt)
  if self.host then
    local event = self.host:service(dt)

    while event do
      if event.type == "connect" then
        print("Connection established")
        state:set(game(self.host, self.peer))
        return
      else
        print("Warning: dropping event " .. event.type)
      end

      event = self.host:service(dt)
    end
  end
end

local fancy = {"|", "/", "-", "\\"}

function index:draw()
  local text = self.status

  if self.failed then
    love.graphics.setColor(255, 100, 100)
    text = "Connection failed:\n" .. text .. "\n\nenter to retry, escape to give up"
  else
    local step = math.floor(love.timer.getTime() * 16 % 4)
    local dots = math.floor(love.timer.getTime() *  4 % 4)
    text = " " .. fancy[step + 1] .. " " .. text .. " " .. fancy[step + 1] .. " "

    for i=1, dots do
      text = "." .. text .. "."
    end
    for i=dots+1, 3 do
      text = "\xC2\xA0" .. text .. "\xC2\xA0"
    end
  end

  love.graphics.printf(text, 10, 100, love.graphics.getWidth() - 20, "center")
end

return function(address)
  return setmetatable({address = address}, {__index = index})
end
