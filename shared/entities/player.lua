local baseentity = require "shared.entities.baseentity"

local player = {
  max_pack_size = 16,
  allow_control = true,
  use_draw = true,
  ent_list_name = "player",
  net_graph_category = "player"
}
player.__index = player
setmetatable(player, baseentity)

function player:new(x, y)
  return setmetatable({x = x, y = y, xv = 0, yv = 0}, self)
end

function player:new_client()
  return setmetatable({x = 0, y = 0, xv = 0, yv = 0}, self)
end

function player:pack(writer)
  writer.f32(self.x)
  writer.f32(self.y)
  writer.f32(self.xv)
  writer.f32(self.yv)
end

function player:unpack(reader)
  self.x = reader.f32()
  self.y = reader.f32()
  self.xv = reader.f32()
  self.yv = reader.f32()
end

function player:update_user(dt, input)
  self.xv = input.x * 250
  self.yv = self.yv + 800 * dt

  if input.y < 0 and self.y >= 400 then
    self.yv = -400
  end

  self.x = self.x + self.xv * dt
  self.y = self.y + self.yv * dt

  self.x = math.max(0, math.min(500 - 15, self.x))
  self.y = math.min(self.y, 400)
end

function player:draw()
  love.graphics.setColor(200, 0, 0)
  love.graphics.rectangle("fill", self.x, self.y, 15, 15)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(tostring(self.id), self.x, self.y - 12)
end

return player
