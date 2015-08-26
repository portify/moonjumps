local packer = require "shared.lib.packer"
local constants = require "shared.constants"
local entity = require "shared.entity"

local index = {}
local mt = {__index = index}

function mt:new(server, peer)
  return setmetatable({
    server = server,
    peer = peer
  }, self)
end

function index:connected()
  print("client " .. self.peer:index() .. " connected")

  local control = entity:new(self.server)
  control.id = self.server.next_entity_id
  self.server.entities[control.id] = control
  self.server.next_entity_id = self.server.next_entity_id + 1
  control.x = 50
  control.y = 50
  control.last_processed_input = -1

  self:set_control(control)
end

function index:disconnected()
  self.server.entities[self:get_control().id] = nil
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
      control:update(dt, input)
      control.last_processed_input = input_sequence_number
    end
  else
    error("unknown packet " .. packet)
  end
end

function index:get_control()
  return self.control_id and self.server.entities[self.control_id]
end

function index:set_control(ent)
  assert(ent.id, "cannot control entity with no net id")
  self.control_id = ent.id
  local writer = packer.writer(5)
  writer.u8(constants.packets.you_are_here)
  writer.u32(entity.id)
  self.peer:send(writer.to_str())
end

return mt
