local CLIENT_SIDE_PREDICTION = true
local SERVER_RECONCILIATION = true

require "enet"
local ser = require "shared.lib.ser"
local Entity = require "shared.Entity"
local SuchLag = require "shared.SuchLag"

local client

function love.load()
  client = {
    entities = {},
    input_sequence_number = 0,
    pending_inputs = {}
  }

  client.host = enet.host_create(nil, 1, 8, 0, 0)

  if client.host == nil then
    error("failed to create host")
  end

  client.peer = client.host:connect("localhost:6780", 8, 0)

  if client.peer == nil then
    error("failed to create peer")
  end
end

function love.update(dt)
  SuchLag.update(dt)

  local event = client.host:service()

  while event do
    if event.type == "connect" then
      -- cool.
    elseif event.type == "disconnect" then
      error("disconnected")
    elseif event.type == "receive" then
      local data = loadstring(event.data)() -- SO SAFE
      if data.type == "hello" then
        client.entity_id = data.entity_id
      elseif data.type == "state" then
        for _, state in ipairs(data) do
          if not client.entities[state.entity_id] then
            client.entities[state.entity_id] = Entity:new()
          end

          local entity = client.entities[state.entity_id]
          entity:unpack(state)

          if state.entity_id == client.entity_id then
            local i = 1

            while i <= #client.pending_inputs do
              local input = client.pending_inputs[i]

              if input.input_sequence_number <= state.last_processed_input then
                table.remove(client.pending_inputs, i)
              else
                entity:update(input.dt, input)
                i = i + 1
              end
            end
          end
        end
      else
        error("unknown type")
      end
    end

    event = client.host:service()
  end

  local entity = client.entity_id and client.entities[client.entity_id]

  if entity == nil then
    return
  end

  local input = entity:build_input()
  input.dt = dt
  input.input_sequence_number = client.input_sequence_number
  client.input_sequence_number = client.input_sequence_number + 1
  SuchLag.delay(0.25, function() client.peer:send(ser(input)) end)

  entity:update(dt, input)
  table.insert(client.pending_inputs, input)
end

function love.draw(stuff)
  love.graphics.print("CLIENT VIEW", 10, 10)
  
  for _, entity in pairs(client.entities) do
    entity:draw()
  end
end
