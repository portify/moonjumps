local entity = {
  max_pack_size = 0,
  net_replicate = true,
  ent_list_name = "<unnamed>",
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

return entity
