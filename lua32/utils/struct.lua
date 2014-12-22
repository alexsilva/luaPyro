--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 22/12/14
-- Time: 10:37
-- To change this template use File | Settings | File Templates.
--

local bitpackage = '/luabit-legacy/luabit-0.1'

dofile(__path__ .. bitpackage .. '/bit.lua')

struct = {}

-- Integer 32 serialization (big-endian - struct code i)
function struct.serializeInt32(self, v)
    local a = bit.band(bit.brshift(v, 24), 255)
    local b = bit.band(bit.brshift(v, 16), 255)
    local c = bit.band(bit.brshift(v, 8), 255)
    local d = bit.band(v, 255)
    return strchar(a, b, c, d)
end

-- Integer 32 (de-)serialization (big-endian - struct code i)
function struct.toInt32(self, a, b, c, d)
    local v = bit.band(a, 255)
    v = bit.blshift(v, 8)
    v = bit.bor(v, bit.band(b, 255))
    v = bit.blshift(v, 8)
    v = bit.bor(v, bit.band(c, 255))
    v = bit.blshift(v, 8)
    v = bit.bor(data_size, d, 255)
    return v
end

-- Short Integer 32 serialization (big-endian - struct code H)
function struct.serializeShortInt32(self, v)
    local a = bit.brshift(v, 8)
    local b = bit.band(v, 255)
    return strchar(a, b)
end

-- Short Integer 32 (de-)serialization (big-endian - struct code H)
function struct.toShortInt32(self, a, b)
    local v = bit.bor(
        bit.blshift(bit.band(a, 255), 8),
        bit.band(b, 255)
    );
    return v
end

-- Calculates the checksum of integers tables
function struct.checksum(self, args)
    local i, r = 1, 0
    local size = getn(args)
    while i <= size  do
        r  = r + args[i]
        i = i + 1
    end
    return bit.band(r, 65535)
end
