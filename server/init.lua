local enet = require "shared.lib.enet"
local unfair = require "shared.lib.unfair"
local packer = require "shared.lib.packer"
local constants = require "shared.constants"
local client = require "server.client"

local index = {}

function index:close()
  for i=1, self.host:peer_count() do
    self.host:get_peer(i):disconnect(constants.disconnect.exiting)
  end

  self.host:service()
  self.host = nil
end

function index:update(dt)
  local clients = self.clients
  local event = self.host:service()

  while event do
    local peer_index = event.peer:index()
    local cl = clients[peer_index]

    if event.type == "connect" then
      assert(cl == nil, "existing peer connect")
      local cl = client:new(self, event.peer)
      clients[peer_index] = cl
      cl:connected(event.data)
    elseif event.type == "disconnect" then
      assert(cl ~= nil, "unknown peer disconnect")
      cl:disconnected(event.data)
      clients[peer_index] = nil
    elseif event.type == "receive" then
      assert(cl ~= nil, "unknown peer receive")
      cl:received(packer.reader(event.data), event.channel)
    end

    event = self.host:service()
  end

  for _, ent in pairs(self.entities) do
    if ent.use_server_update then
      ent:update_server(dt)
    end
  end

  for _, cl in pairs(self.clients) do
    cl:consider_send_update()
  end
end

function index:add(ent)
  if ent.id ~= nil then return end

  ent.id = self.next_entity_id
  ent.server = self
  self.entities[ent.id] = ent
  self.next_entity_id = self.next_entity_id + 1

  local writer = packer.writer(7 + ent.max_pack_size)
  writer.u8(constants.packets.entity_add)
  writer.u32(ent.id)
  writer.u16(0)
  ent:pack(writer)
  self.host:broadcast(writer.to_str())
end

function index:remove(ent)
  if ent.id == nil then return end

  local writer = packer.writer(5)
  writer.u8(constants.packets.entity_remove)
  writer.u32(ent.id)
  self.host:broadcast(writer.to_str())

  self.entities[ent.id] = nil
  ent.id = nil
  ent.server = nil
end

return function(config)
  local address = config.address or (config.private and "localhost" or "*")
  local port = config.port or constants.default_port
  local host = enet.host_create(address .. ":" .. port,
    config.max_peers or 64, constants.channels,
    config.in_bandwidth or 0, config.out_bandwidth or 0)

  if host == nil then
    error("failed to bind to " .. address .. ":" .. port)
  end

  if config.unfair then
    host = unfair(host,
      config.unfair.latency or 0,
      config.latency.jitter or 0,
      config.latency.loss or 0)
  end

  local t = {
    host = host,
    clients = {},
    entities = {},
    next_entity_id = 0
  }

  return setmetatable(t, {__index = index})
end
