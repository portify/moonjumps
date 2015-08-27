-- FIXME: endianness!
local ffi = require "ffi"

-- FIXME: read these dynamically
local ct_max = {
  u8  = 2^ 8 - 1,
  u16 = 2^16 - 1,
  u32 = 2^32 - 1,
  u64 = 2^64 - 1,
}

local function reader(s)
  local len = #s
  local ptr = ffi.new("unsigned char[?]", #s, s)

  local function read_str(n)
    assert(len >= n, "read past eof")
    local str = ffi.string(ptr, n)
    len = len - n
    ptr = ptr + n
    return str
  end

  local function read(ct)
    local size = ffi.sizeof(ct)
    assert(len >= size, "read past eof")
    local cdata = ffi.cast(ct .. "*", ptr)[0]
    len = len - size
    ptr = ptr + size
    return cdata
  end

  return {
    eof = function() return len == 0 end,

    u8  = function() return read("uint8_t") end,
    u16 = function() return read("uint16_t") end,
    u32 = function() return read("uint32_t") end,
    u64 = function() return read("uint64_t") end,
    s8  = function() return read("int8_t") end,
    s16 = function() return read("int16_t") end,
    s32 = function() return read("int32_t") end,
    s64 = function() return read("int64_t") end,
    f32 = function() return read("float") end,
    f64 = function() return read("double") end,

    str_u8 = function()
      local n = tonumber(read("unsigned char"))
      return read_str(n)
    end
  }
end

local function writer(len)
  local buffer = ffi.new("unsigned char[?]", len)
  local ptr = buffer

  local function write_raw(src, n)
    assert(len - (ptr - buffer) >= n, "write past eof")
    ffi.copy(ptr, src, len)
    ptr = ptr + n
  end

  local function write(ct, init)
    local size = ffi.sizeof(ct)
    assert(len - (ptr - buffer) >= size, "write past eof")
    ffi.cast(ct .. "*", ptr)[0] = ffi.new(ct, init)
    ptr = ptr + size
  end

  return {
    buffer_size = function() return len end,
    buffer_remaining = function() return len - tonumber(ptr - buffer) end,
    data_size = function() return tonumber(ptr - buffer) end,

    to_str = function()
      return ffi.string(buffer, tonumber(ptr - buffer))
    end,

    u8  = function(v) write("uint8_t", v) end,
    u16 = function(v) write("uint16_t", v) end,
    u32 = function(v) write("uint32_t", v) end,
    u64 = function(v) write("uint64_t", v) end,
    s8  = function(v) write("int8_t", v) end,
    s16 = function(v) write("int16_t", v) end,
    s32 = function(v) write("int32_t", v) end,
    s64 = function(v) write("int64_t", v) end,
    f32 = function(v) write("float", v) end,
    f64 = function(v) write("double", v) end,

    str_u8 = function(s)
      assert(#s <= ct_max.u8, "string larger than u8")
      write("unsigned char", #s)
      write_raw(ffi.new("unsigned char[?]", #s, s), #s)
    end
  }
end

return {
  reader = reader,
  writer = writer
}
