require "enet"
local ser = require "shared.lib.ser"
local Entity = require "shared.Entity"
local SuchLag = require "shared.SuchLag"

local server

function love.load()
  server = {
    clients = {},
    entities = {},
    last_processed_input = {}
  }

  server.host = enet.host_create("*:6780", 64, 8, 0, 0)

  if server.host == nil then
    error("failed to create host")
  end
end

function love.update(dt)
  SuchLag.update(dt)
  local event = server.host:service()
  local aaa = false

  while event do
    local peer_index = event.peer:index()

    if event.type == "connect" then
      local oh_ok = event
      SuchLag.delay(0.25, function() oh_ok.peer:send(ser({type = "hello", entity_id = peer_index})) end)
      server.entities[peer_index] = Entity:new()
      server.entities[peer_index].entity_id = peer_index
      server.entities[peer_index].last_processed_input = -1
      server.entities[peer_index].x = 50
      server.entities[peer_index].y = 50
      aaa = true
    elseif event.type == "disconnect" then
      server.entities[peer_index] = nil
    elseif event.type == "receive" then
      local data = loadstring(event.data)() -- SO SAFE
      server.entities[peer_index]:update(data.dt, data)
      server.entities[peer_index].last_processed_input = data.input_sequence_number
    end

    event = server.host:service()
  end

  local world_state = {type = "state"}

  for id, entity in pairs(server.entities) do
    local entry = entity:pack()

    entry.entity_id = id
    entry.last_processed_input = entity.last_processed_input

    table.insert(world_state, entry)
  end

  aaa = true
  if aaa then SuchLag.delay(0.25, function() server.host:broadcast(ser(world_state)) end) end
end

function love.draw()
  love.graphics.print("SERVER VIEW", 10, 10)

  for id, entity in pairs(server.entities) do
    entity:draw()
  end
end
