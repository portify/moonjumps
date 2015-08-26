local enet = require "shared.lib.enet"
local unfair = require "shared.lib.unfair"
local packer = require "shared.lib.packer"
local constants = require "shared.constants"

local client = require "server.client"

local server

function love.load()
  love.window.setMode(500, 500, {x = 50, y = 60})
  love.window.setTitle("Server")

  server = {
    clients = {},
    entities = {},
    next_entity_id = 0,
    last_processed_input = {}
  }

  server.host = enet.host_create("*:6780", 64, 8, 0, 0)
  server.host = unfair(server.host, 0)

  if server.host == nil then
    error("failed to create host")
  end
end

local function build_update()
  local size = 5
  local count = 0

  -- TODO: find a better way of calculating proper buffer size
  for _, ent in pairs(server.entities) do
    size = size + 8 + ent:pack_size()
    count = count + 1
  end

  local writer = packer.writer(size)
  writer.u8(constants.packets.server_state)
  writer.u32(count)

  for id, ent in pairs(server.entities) do
    writer.u32(id)
    writer.u32(ent.last_processed_input)
    ent:pack(writer)
  end

  return writer.to_str()
end

function love.update()
  local event = server.host:service()

  while event do
    local peer_index = event.peer:index()
    local cl = server.clients[peer_index]

    if event.type == "connect" then
      assert(cl == nil, "existing peer connect")
      server.clients[peer_index] = client:new(server, event.peer)
      server.clients[peer_index]:connected(event.data)
    elseif event.type == "disconnect" then
      assert(cl ~= nil, "unknown peer disconnect")
      cl:disconnected(event.data)
      server.clients[peer_index] = nil
    elseif event.type == "receive" then
      assert(cl ~= nil, "unknown peer receive")
      cl:received(packer.reader(event.data), event.channel)
    end

    event = server.host:service()
  end

  server.host:broadcast(build_update())
end

function love.draw()
  for _, ent in pairs(server.entities) do
    ent:draw()
  end
end
