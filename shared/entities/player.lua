local baseentity = require "shared.entities.baseentity"

local player = {
  max_pack_size = 16,
  ent_list_name = "player",
  net_graph_category = "player"
}
player.__index = player
setmetatable(player, baseentity)

function player:new(x, y)
  if not self.image then
    self.image = love.graphics.newImage("bloat/pyro-blue-stand.png")
  end
  return setmetatable({x = x, y = y, xv = 0, yv = 0, d = 1}, self)
end

function player:new_client()
  if not self.image then
    self.image = love.graphics.newImage("bloat/pyro-blue-stand.png")
  end
  return setmetatable({x = 0, y = 0, xv = 0, yv = 0, d = 1}, self)
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

local jumpStrength = 240
local runPower = 990
local controlFactor = 1
local baseFriction = 1.15

function player:update_user(dt, input)
  if self.y >= 400 and input.y < 0 then
    self.yv = -jumpStrength
  end

  local ix = math.max(-1, math.min(1, input.x))
  self.xv = self.xv + runPower * controlFactor * dt * ix
  self.xv = self.xv / baseFriction

  if math.abs(self.xv) < 0.195 then
    self.xv = 0
  end

  if self.y < 400 then
    self.yv = math.min(300, self.yv + 600 * dt)
  end

  -- limit hspeed vspeed to 15

  self.x = self.x + self.xv * dt
  self.y = self.y + self.yv * dt

  self.x = math.max(8, math.min(500 - 8, self.x))
  self.y = math.min(self.y, 400)

  if input.x < 0 then
    self.d = -1
  elseif input.x > 0 then
    self.d = 1
  end
end

function player:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.image, self.x, self.y, 0, self.d, 1, 32, 64)
end

return player
