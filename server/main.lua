local server = require "server"
local entities = require "shared.entities"
local main

function love.load()
  love.window.setMode(500, 500, {x = 50, y = 60})
  love.window.setTitle("Server")
  love.graphics.setFont(love.graphics.newFont("bloat/SourceCodePro-Regular.ttf", 12))

  main = server {}
  main:add(require("shared.entities.shitty_drawn_skybox"):new())
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
    table.insert(lines, "  ping  " .. cl.peer:round_trip_time() .. " ms")
    table.insert(lines, "  seq   " .. cl.last_processed_input)
  end

  love.graphics.setColor(0, 0, 0)
  love.graphics.printf(table.concat(lines, "\n"):gsub(" ", "\xC2\xA0"), 4, 2, love.graphics.getWidth() - 8)
  entities.show(main.entities)
end
