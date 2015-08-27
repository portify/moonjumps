-- wraps enet host to simulate poor network
return function(host, latency, jitter, loss)
  latency = latency or 250
  jitter = jitter or 0
  loss = loss or 0

  if latency <= 0 and jitter <= 0 and loss <= 0 then
    return host
  end

  local pending = {}

  local function add(delay, func)
    if delay <= 0 then
      func()
      return
    end

    table.insert(pending, {
      time = love.timer.getTime() + delay,
      func = func
    })
  end

  local function random()
    return (latency +
      love.math.random() * jitter - jitter / 2) / 1000
  end

  local function wrap_peer(peer)
    return setmetatable({
      send = function(_, a, b, c)
        if love.math.random() >= loss then
          add(random(), function() peer:send(a, b, c) end)
        end
      end,
      round_trip_time = function(_, value)
        if value then
          return peer:round_trip_time(value)
        end
        return peer:round_trip_time() + latency
      end
    }, {
      __index = function(_, key)
        return function(_, ...)
          peer[key](peer, ...)
        end
      end
    })
  end

  return setmetatable({
    service = function(_, ...)
      local t = love.timer.getTime()
      local i = 1

      while i <= #pending do
        if t >= pending[i].time then
          pending[i].func()
          table.remove(pending, i)
        else
          i = i + 1
        end
      end

      return host:service(...)
    end,

    get_peer = function(_, index)
      return wrap_peer(host:get_peer(index))
    end,

    connect = function(_, ...)
      return wrap_peer(host:connect(...))
    end,

    broadcast = function(self, ...)
      for i=1, host:peer_count() do
        self:get_peer(i):send(...)
      end
    end
  }, {
    __index = function(_, key)
      return function(_, ...)
        host[key](host, ...)
      end
    end
  })
end
