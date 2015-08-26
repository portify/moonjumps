local delays = {}

return {
  delay = function(seconds, func)
    table.insert(delays, {seconds, func})
  end,
  update = function(dt)
    local i = 1

    while i <= #delays do
      local delay = delays[i]
      delay[1] = delay[1] - dt

      if delay[1] <= 0 then
        delay[2]()
        table.remove(delays, i)
      else
        i = i + 1
      end
    end
  end
}
