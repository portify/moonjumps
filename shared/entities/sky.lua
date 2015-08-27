local baseentity = require "shared.entities.baseentity"

local sky = {
  ent_list_name = "sky"
}
sky.__index = sky
setmetatable(sky, baseentity)

function sky:new()
  return setmetatable({}, self)
end

function sky:new_client()
  return setmetatable({}, self)
end

function sky.draw()
  love.graphics.setColor(100, 255, 255)
  love.graphics.rectangle("fill", 0, 0, 500, 400)
  love.graphics.setColor(0, 200, 0)
  love.graphics.rectangle("fill", 0, 400, 500, 100)
end

return sky
