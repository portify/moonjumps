local enet = require "shared.lib.enet"
local unfair = require "shared.lib.unfair"
local packer = require "shared.lib.packer"
local constants = require "shared.constants"

local server = require "server"
local client = require "server.client"

local main

function love.load()
  love.window.setMode(500, 500, {x = 50, y = 60})
  love.window.setTitle("Server")

  main = server {
    -- config
  }
end

function love.update(dt)
  main:update(dt)
end

function love.draw()
  love.graphics.push()

  for _, ent in pairs(main.entities) do
    if ent.use_draw then
      ent:draw()
    end
  end

  love.graphics.pop()

  for _, ent in pairs(main.entities) do
    if ent.use_draw_abs then
      ent:draw_abs()
    end
  end

  local lines = {}

  for i, cl in pairs(main.clients) do
    table.insert(lines, "client " .. i)
    table.insert(lines, "\xC2\xA0\xC2\xA0ping " .. cl.peer:round_trip_time())
    table.insert(lines, "\xC2\xA0\xC2\xA0seq  " .. cl.last_processed_input)
  end

  love.graphics.printf(table.concat(lines, "\n"), 10, 10, love.graphics.getWidth() - 20)
end
