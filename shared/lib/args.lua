local arg_start

do
  local i = 1

  while i <= #arg do
    local _, _, m = string.find(arg[i], "%-%-(.+)")

    if m and love.arg.options[m] then
      i = i + love.arg.options[m].a + 1
    else
      break
    end
  end

  arg_start = i
end

return {
  flag = function(s)
    for i=arg_start, #arg do
      if arg[i] == s then
        return true
      end
    end

    return false
  end
}
