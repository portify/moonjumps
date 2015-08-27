local packer = require "shared.lib.packer"
local constants = require "shared.constants"
local player = require "shared.entities.player"

local index = {}
local mt = {__index = index}

function mt:new(server, peer)
  return setmetatable({
    server = server,
    peer = peer,
    last_processed_input = -1
  }, self)
end

function index:connected()
  print("client " .. self.peer:index() .. " connected")

  local size = 1

  for _, ent in pairs(self.server.entities) do
    size = size + 6 + ent.max_pack_size
  end

  local writer = packer.writer(size)
  writer.u8(constants.packets.entity_add)

  for id, ent in pairs(self.server.entities) do
    writer.u32(id)
    writer.u16(0)
    ent:pack(writer)
  end

  self.peer:send(writer.to_str())

  self.player = player:new(self.server, 50, 50)
  self.server:add(self.player)
  -- self.player.last_processed_input = -1
  -- self.player.id = self.server.next_entity_id
  -- self.server.entities[self.player.id] = self.player
  -- self.server.next_entity_id = self.server.next_entity_id + 1

  self:set_control(self.player)
end

function index:disconnected()
  self.server:remove(self.player)
  -- self.server.entities[self.player.id] = nil
  print("client " .. self.peer:index() .. " disconnected")
end

function index:received(reader)
  local packet = reader.u8()

  if packet == constants.packets.client_input then
    local input_sequence_number = reader.u32() -- TODO: handle sequence number wrap
    local dt = reader.f32()
    local input = {}
    input.x = reader.f32()
    input.y = reader.f32()

    local control = self:get_control()

    if control ~= nil then
      control:update_user(dt, input, true)
      self.last_processed_input = input_sequence_number
    end
  else
    error("unknown packet " .. packet)
  end
end

function index:get_control()
  return self.control_id and self.server.entities[self.control_id]
end

function index:set_control(ent)
  assert(ent.allow_control, "cannot control this type of entity", 1)
  assert(ent.id, "cannot control entity with no net id", 1)
  self.control_id = ent.id
  local writer = packer.writer(5)
  writer.u8(constants.packets.entity_control)
  writer.u32(ent.id)
  self.peer:send(writer.to_str())
end

return mt
