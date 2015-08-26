local enet = require "shared.lib.enet"
local unfair = require "shared.lib.unfair"
local packer = require "shared.lib.packer"
local entity = require "shared.entity"
local constants = require "shared.constants"

local client

function love.load()
  love.window.setMode(500, 500, {x = 600, y = 60})
  love.window.setTitle("Client")

  client = {
    entities = {},
    input_sequence_number = 0,
    pending_inputs = {}
  }

  client.host = enet.host_create(nil, 1, 8, 0, 0)
  client.host = unfair(client.host, 0)

  if client.host == nil then
    error("failed to create host")
  end

  client.peer = client.host:connect("192.168.1.15:6780", 8, 0)

  if client.peer == nil then
    error("failed to create peer")
  end
end

local function handle_receive(reader)
  local packet = reader.u8()

  if packet == constants.packets.you_are_here then
    client.entity_id = reader.u32()
  elseif packet == constants.packets.server_state then
    local count = reader.u32()

    for _=1, count do
      local entity_id = reader.u32()
      local last_processed_input = reader.u32()

      if not client.entities[entity_id] then
        client.entities[entity_id] = entity:new()
      end

      local ent = client.entities[entity_id]
      ent:unpack(reader)

      if entity_id == client.entity_id then
        local i = 1

        while i <= #client.pending_inputs do
          local input = client.pending_inputs[i]

          if input.input_sequence_number <= last_processed_input then
            table.remove(client.pending_inputs, i)
          else
            ent:update(input.dt, input)
            i = i + 1
          end
        end
      end
    end
  else
    error("unknown packet " .. packet)
  end
end

function love.update(dt)
  local event = client.host:service()

  while event do
    if event.type == "connect" then
      print("connected")
    elseif event.type == "disconnect" then
      error("disconnected")
    elseif event.type == "receive" then
      handle_receive(packer.reader(event.data))
    end

    event = client.host:service()
  end

  local ent = client.entity_id and client.entities[client.entity_id]

  if ent == nil then
    return
  end

  local input = {x = 0, y = 0}

  if love.keyboard.isDown("right") then input.x = input.x + 1 end
  if love.keyboard.isDown("left" ) then input.x = input.x - 1 end
  if love.keyboard.isDown("down" ) then input.y = input.y + 1 end
  if love.keyboard.isDown("up"   ) then input.y = input.y - 1 end

  input.dt = dt
  input.input_sequence_number = client.input_sequence_number
  client.input_sequence_number = client.input_sequence_number + 1

  local writer = packer.writer(17)
  writer.u8(constants.packets.client_input)
  writer.u32(input.input_sequence_number)
  writer.f32(input.dt)
  writer.f32(input.x)
  writer.f32(input.y)
  client.peer:send(writer.to_str(), 1, "unreliable")
  client.sent = writer.data_size()

  ent:update(dt, input)
  table.insert(client.pending_inputs, input)
end

function love.draw()
  for _, ent in pairs(client.entities) do
    ent:draw()
  end
end
