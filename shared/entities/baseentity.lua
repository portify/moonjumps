local entity = {
  max_pack_size = 0,
  allow_control = false,
  use_server_update = false,
  use_client_update = false,
  use_draw = false,
  use_draw_abs = false,
  net_graph_category = "other"
}
entity.__index = entity

function entity:new()
  return setmetatable({}, self)
end

function entity:new_client()
  return setmetatable({}, self)
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
