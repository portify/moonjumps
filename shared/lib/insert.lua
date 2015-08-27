local function default_cmp(a, b)
  if a < b then
    return -1
  elseif a > b then
    return 1
  else
    return 0
  end
end

return {
  sorted = function(t, v, cmp)
    cmp = cmp or default_cmp

    for i=#t, 1, -1 do
      if cmp(t[i], v) == -1 then
        table.insert(t, i + 1)
        return
      end
    end

    table.insert(t, 1, v)
  end
}
