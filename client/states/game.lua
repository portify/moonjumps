local packer = require "shared.lib.packer"
local constants = require "shared.constants"
local entities = require "shared.entities"
local player = require "shared.entities.player"

local index = {}

function index:enter()
  self.net_time = 0
end

function index:leave()
  if self.host and self.peer then
    self.peer:disconnect(1)
    self.host:service()
  end
end

function index:quit()
  self:leave()
end

function index:handle_receive(reader)
  local packet = reader.u8()

  if packet == constants.packets.entity_add then
    while not reader.eof() do
      local id = reader.u32()
      local type = reader.u16()
      -- self.entities[id] = player:new_client()
      self.entities[id] = entities.from_id(type):new_client()
      self.entities[id].client = self
      self.entities[id].id = id
      self.entities[id]:unpack(reader)
    end
  elseif packet == constants.packets.entity_remove then
    while not reader.eof() do
      self.entities[reader.u32()] = nil
    end
  elseif packet == constants.packets.entity_control then
    self.entity_id = reader.u32()
  elseif packet == constants.packets.server_state then
    local last_processed_input = reader.u32()
    local count = reader.u32()

    self.input_ack = last_processed_input

    for _=1, count do
      local entity_id = reader.u32()

      if not self.entities[entity_id] then
        -- self.entities[entity_id] = player:new_client()
        error("fuck")
      end

      local ent = self.entities[entity_id]
      ent:unpack(reader)

      if entity_id == self.entity_id then
        local i = 1

        while i <= #self.pending_inputs do
          local input = self.pending_inputs[i]

          if input.input_seq <= last_processed_input then
            table.remove(self.pending_inputs, i)
          else
            ent:update_user(input.dt, input, false)
            i = i + 1
          end
        end
      end
    end
  else
    error("unknown packet " .. packet)
  end
end

function index:update(dt)
  self.net_time = self.net_time + dt
  local event = self.host:service()

  while event do
    if event.type == "connect" then
      print("connected")
    elseif event.type == "disconnect" then
      error("disconnected")
    elseif event.type == "receive" then
      self:handle_receive(packer.reader(event.data))
    end

    event = self.host:service()
  end

  for _, ent in pairs(self.entities) do
    if ent.use_client_update then
      ent:update_client(dt)
    end
  end

  local ent = self.entity_id and self.entities[self.entity_id]

  if ent == nil then
    return
  end

  local input = {x = 0, y = 0}

  if love.keyboard.isDown("right") then input.x = input.x + 1 end
  if love.keyboard.isDown("left" ) then input.x = input.x - 1 end
  if love.keyboard.isDown("down" ) then input.y = input.y + 1 end
  if love.keyboard.isDown("up"   ) then input.y = input.y - 1 end

  input.dt = dt
  input.input_seq = self.input_seq
  self.input_seq = self.input_seq + 1

  local writer = packer.writer(17)
  writer.u8(constants.packets.client_input)
  writer.u32(input.input_seq)
  writer.f32(input.dt)
  writer.f32(input.x)
  writer.f32(input.y)
  self.peer:send(writer.to_str(), 1, "unreliable")

  ent:update_user(dt, input, true)
  table.insert(self.pending_inputs, input)
end

function index:draw()
  love.graphics.push()

  for _, ent in pairs(self.entities) do
    if ent.use_draw then
      ent:draw()
    end
  end

  love.graphics.pop()

  for _, ent in pairs(self.entities) do
    if ent.use_draw_abs then
      ent:use_draw_abs()
    end
  end

  local lines = {
    "ping  " .. self.peer:round_trip_time() .. " ms",
    "up    " .. math.floor(self.host:total_sent_data() / self.net_time) .. " b/s",
    "down  " .. math.floor(self.host:total_received_data() / self.net_time) .. " b/s",
    "seq   " .. self.input_seq,
    "ack   " .. self.input_ack,
    "qlen  " .. #self.pending_inputs,
  }

  love.graphics.setColor(0, 0, 0)
  love.graphics.printf(table.concat(lines, "\n"):gsub(" ", "\xC2\xA0"), 4, 2, love.graphics.getWidth() - 8)
  entities.show(self.entities, self.entity_id)
end

return function(host, peer)
  return setmetatable({
    host = host,
    peer = peer,
    entities = {},
    input_seq = 0,
    input_ack = -1,
    pending_inputs = {}
  }, {__index = index})
end
