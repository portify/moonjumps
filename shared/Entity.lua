local Entity = {}
Entity.__index = Entity

function Entity:new()
  return setmetatable({x = 0, y = 0, xv = 0, yv = 0}, self)
end

function Entity:pack()
  return {x = self.x, y = self.y, xv = self.xv, yv = self.yv}
end

function Entity:unpack(t)
  self.x = t.x
  self.y = t.y
  self.xv = t.xv
  self.yv = t.yv
end

function Entity:build_input()
  local input = {x = 0, y = 0}

  if love.keyboard.isDown("right") then input.x = input.x + 1 end
  if love.keyboard.isDown("left" ) then input.x = input.x - 1 end
  if love.keyboard.isDown("down" ) then input.y = input.y + 1 end
  if love.keyboard.isDown("up"   ) then input.y = input.y - 1 end

  return input
end

function Entity:update(dt, input)
  self.xv = input.x * 100
  self.yv = self.yv + 200 * dt

  if input.y > 0 and self.y >= 400 then
    self.yv = -500
  end

  self.x = self.x + self.xv * dt
  self.y = self.y + self.yv * dt

  self.y = math.min(self.y, 400)
end

function Entity:draw()
  love.graphics.rectangle("fill", self.x, self.y, 15, 15)
end

return Entity
