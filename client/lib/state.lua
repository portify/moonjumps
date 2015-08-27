local stack = {}

local function new(t)
  return setmetatable(t or {}, {__index = stack})
end

function stack:valid()
  return #self ~= 0
end

function stack:current()
  return self[#self]
end

function stack:clear()
  while #self ~= 0 do
    self:pop()
  end
end

function stack:push(t)
  assert(type(t) == "table", "expected table in arg 1", 1)

  local prev = self[#self]
  if prev and prev.pause then
    prev:pause(t, self)
  end

  table.insert(self, t)
  if t.enter then
    return t:enter(prev, self)
  end
end

function stack:pop()
  assert(#self ~= 0, "pop from empty stack", 1)

  local top = table.remove(self)
  if top.leave then
    top:leave(self)
  end

  local next = self[#self]
  if next and next.resume then
    return next:resume(self)
  end
end

function stack:set(t)
  assert(type(t) == "table", "expected table in arg 1", 1)
  self:clear()
  return self:push(t)
end

function stack:set_or_pop(t)
  assert(type(t) == "table", "expected table in arg 1", 1)
  if #self > 1 then
    return self:pop()
  else
    return self:push(t)
  end
end

function stack:set_top(t)
  if #self ~= 0 then
    self:pop()
  end

  return self:push(t)
end

function stack:send(event, ...)
  local t = self[#self]

  if t and t[event] then
    return t[event](t, ...)
  end
end

local love_events = {
  "update", "draw",
  "keypressed", "keyreleased", "textinput", "textedited", "mousemoved",
  "mousepressed", "mousereleased", "wheelmoved", "touchpressed",
  "touchreleased", "touchmoved", "joystickpressed", "joystickreleased",
  "joystickaxis", "joystickhat", "gamepadpressed", "gamepadreleased",
  "gamepadaxis", "joystickadded", "joystickremoved", "focus", "mousefocus",
  "visible", "quit", "threaderror", "resize", "filedropped",
  "directorydropped", "lowmemory"
}

function stack:inject(target, events)
  if target == nil then
    target = _G.love
    assert(type(target) == "table", "no target specified and love not found", 1)
  elseif type(target) ~= "table" then
    error("expected table or nil in arg 1", 1)
  end

  if events == nil then
    events = love_events
  elseif type(events) ~= "table" then
    error("expected table or nil in arg 2", 1)
  end

  for _, event in ipairs(events) do
    if target[event] then
      local super = target[event]
      target[event] = function(...)
        super(...)
        return self:send(event, ...)
      end
    else
      target[event] = function(...)
        return self:send(event, ...)
      end
    end
  end
end

return new { new = new }
