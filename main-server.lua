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

  -- move this
  function server:add(ent)
    assert(ent.id == nil, "attempting to re-add entity", 1)
    ent.id = self.next_entity_id
    self.entities[ent.id] = ent
    self.next_entity_id = self.next_entity_id + 1
    local writer = packer.writer(7 + ent.max_pack_size)
    writer.u8(constants.packets.entity_add)
    writer.u32(ent.id)
    writer.u16(0)
    ent:pack(writer)
    self.host:broadcast(writer.to_str())
  end

  server.host = enet.host_create("*:6780", 64, 8, 0, 0)
  server.host = unfair(server.host, 500)

  if server.host == nil then
    error("failed to create host")
  end
end

local function build_update(cl)
  local size = 6
  local count = 0

  -- TODO: find a better way of calculating proper buffer size
  for _, ent in pairs(server.entities) do
    size = size + 8 + ent.max_pack_size
    count = count + 1
  end

  local writer = packer.writer(size)
  writer.u8(constants.packets.server_state)
  writer.u32(cl.last_processed_input)
  writer.u32(count)

  for id, ent in pairs(server.entities) do
    writer.u32(id)
    ent:pack(writer)
  end

  return writer.to_str()
end

function love.update(dt)
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

  for _, ent in pairs(server.entities) do
    if ent.use_server_update then
      ent:update_server(dt)
    end
  end

  for _, cl in pairs(server.clients) do
    cl.peer:send(build_update(cl))
  end
end

function love.draw()
  love.graphics.push()

  for _, ent in pairs(server.entities) do
    if ent.use_draw then
      ent:draw()
    end
  end

  love.graphics.pop()

  for _, ent in pairs(server.entities) do
    if ent.use_draw_abs then
      ent:draw_abs()
    end
  end

  local lines = {}

  for i, cl in pairs(server.clients) do
    table.insert(lines, "client " .. i)
    table.insert(lines, "\xC2\xA0\xC2\xA0ping " .. cl.peer:round_trip_time())
    table.insert(lines, "\xC2\xA0\xC2\xA0seq  " .. cl.last_processed_input)
  end

  love.graphics.printf(table.concat(lines, "\n"), 10, 10, love.graphics.getWidth() - 20)
end
