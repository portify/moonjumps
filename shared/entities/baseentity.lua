local entity = {
  pack_size = 0,
  allow_control = false,
  use_server_update = false,
  use_client_update = false,
  use_draw = false,
  use_draw_abs = false
}
entity.__index = entity

function entity:new()
  return setmetatable({x = 0, y = 0, xv = 0, yv = 0}, self)
end

function entity.pack()
end

function entity.unpack()
end

function entity.update_server()
  error("missing update_server implementation", 1)
end

function entity.update_client()
  error("missing update_client implementation", 1)
end

function entity.update_user()
  error("missing update_user implementation", 1)
end

function entity.draw()
  error("missing draw implementation", 1)
end

function entity.draw_abs()
  error("missing draw_abs implementation", 1)
end

return entity
