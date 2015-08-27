local entities = {
  require "shared.entities.player",
  require "shared.entities.sky"
}

local ids = {}

for id, mt in ipairs(entities) do
  ids[mt] = id
end

return {
  to_id = function(entity)
    return ids[getmetatable(entity)]
  end,
  from_id = function(id)
    return entities[id]
  end,
  show = function(ents, control)
    local lines = {}

    for id, ent in pairs(ents) do
      if id == control then
        table.insert(lines, "* " .. ent.ent_list_name .. " " .. id)
      else
        table.insert(lines, ent.ent_list_name .. " " .. tostring(id))
      end
    end

    love.graphics.printf(table.concat(lines, "\n"), 4, 2, love.graphics.getWidth() - 8, "right")
  end
}
