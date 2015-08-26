local VIEW_SIZE = {400, 100}
local CLIENT_VIEW = {32, 32}
local SERVER_VIEW = {32, 264}
local CLIENT_SERVER_LAG = 250
local SERVER_RECONCILIATION = true
local CLIENT_SIDE_PREDICTION = true
local SERVER_UPDATE_RATE = 8 -- every 8 client updates the server sends state

local Entity = {}
Entity.__index = Entity

function Entity:new()
  return setmetatable({x = 0, speed = 2}, self)
end

function Entity:applyInput(input)
  self.x = self.x + input.press_time * self.speed
end

local LagNetwork = {}
LagNetwork.__index = LagNetwork

function LagNetwork:new()
  return setmetatable({messages = {}}, self)
end

function LagNetwork:send(lams, message)
  table.insert(self.messages, {recv_ts = love.timer.getTime() + lams / 1000,
                               payload = message})
end

function LagNetwork:receive()
  local now = love.timer.getTime()
  for i, message in ipairs(self.messages) do
    if message.recv_ts <= now then
      table.remove(self.messages, i)
      return message.payload
    end
  end
end

local Client = {}
Client.__index = Client

function Client:new()
  return setmetatable({
    entity = nil,
    network = LagNetwork:new(),
    server = nil,
    entity_id = nil,
    input_sequence_number = 0,
    pending_inputs = {}
  }, self)
end

function Client:update()
  self:processServerMessages()

  if self.entity == nil then
    return
  end

  self:processInputs()
end

function Client:processInputs()
  local dt_sec = love.timer.getDelta()
  local input

  if love.keyboard.isDown("right") then
    input = {press_time = dt_sec}
  elseif love.keyboard.isDown("left") then
    input = {press_time = -dt_sec}
  else
    return
  end

  input.input_sequence_number = self.input_sequence_number
  self.input_sequence_number = self.input_sequence_number + 1
  input.entity_id = self.entity_id
  self.server.network:send(CLIENT_SERVER_LAG, input)

  if CLIENT_SIDE_PREDICTION then
    self.entity:applyInput(input)
  end

  table.insert(self.pending_inputs, input)
end

function Client:processServerMessages()
  while true do
    local message = self.network:receive()

    if message == nil then
      break
    end

    for _, state in ipairs(message) do
      if state.entity_id == self.entity_id then
        if not self.entity then
          self.entity = Entity:new()
        end

        self.entity.x = state.position

        if SERVER_RECONCILIATION then
          local i = 1

          while i <= #self.pending_inputs do
            local input = self.pending_inputs[i]

            if input.input_sequence_number <= state.last_processed_input then
              table.remove(self.pending_inputs, i)
            else
              self.entity:applyInput(input)
              i = i + 1
            end
          end
        else
          self.pending_inputs = {}
        end
      end
    end
  end
end

local Server = {}
Server.__index = Server

function Server:new()
  return setmetatable({
    clients = {},
    entities = {},
    last_processed_input = {},
    network = LagNetwork:new()
  }, self)
end

function Server:connect(client)
  client.server = self
  client.entity_id = #self.clients + 1
  table.insert(self.clients, client)

  local entity = Entity:new()
  table.insert(self.entities, entity)
  entity.entity_id = client.entity_id

  entity.x = 5
end

function Server:update(send_state)
  self:processInputs()
  if send_state then self:sendWorldState() end
end

-- skipping validateInput

function Server:processInputs()
  while true do
    local message = self.network:receive()

    if message == nil then
      break
    end

    local id = message.entity_id
    self.entities[id]:applyInput(message)
    self.last_processed_input[id] = message.input_sequence_number
  end
end

function Server:sendWorldState()
  local world_state = {}

  for i=1, #self.clients do
    local entity = self.entities[i]
    table.insert(world_state, {
      entity_id = entity.entity_id,
      position = entity.x,
      -- last_processed_input = self.last_processed_input[i]
      last_processed_input = self.last_processed_input[i] or -1
    })
  end

  for _, client in ipairs(self.clients) do
    client.network:send(CLIENT_SERVER_LAG, world_state)
  end
end

local client, server, updates

function love.load()
  client = Client:new()
  server = Server:new()
  server:connect(client)
  updates = 0
end

function love.update()
  server:update(updates == 0)

  client:update()
  updates = (updates + 1) % SERVER_UPDATE_RATE
end

local function renderWorld(view, ents)
  love.graphics.setColor(255, 255, 255)
  love.graphics.rectangle("fill", view[1], view[2], VIEW_SIZE[1], VIEW_SIZE[2])

  for _, ent in ipairs(ents) do
    local radius = VIEW_SIZE[2] * 0.9 / 2
    local x = ent.x * VIEW_SIZE[2]
    love.graphics.setColor(0, 200, 0)
    love.graphics.circle("fill", view[1] + x, view[2] + VIEW_SIZE[2] / 2, radius)
  end
end

function love.draw()
  renderWorld(CLIENT_VIEW, {client.entity})
  renderWorld(SERVER_VIEW, server.entities)
end
