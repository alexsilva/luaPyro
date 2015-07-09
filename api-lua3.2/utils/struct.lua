--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 22/12/14
-- Time: 10:37
-- To change this template use File | Settings | File Templates.
--

struct = {}

-- Integer 32 serialization (big-endian - struct code i)
function struct.serializeInt32(self, v)
    local a = band(brshift(v, 24), 255)
    local b = band(brshift(v, 16), 255)
    local c = band(brshift(v, 8), 255)
    local d = band(v, 255)
    return strchar(a, b, c, d)
end

-- Integer 32 (de-)serialization (big-endian - struct code i)
function struct.toInt32(self, a, b, c, d)
    local x = band(a, 255)
    x = blshift(x, 8)
    x = bor(x, band(b, 255))
    x = blshift(x, 8)
    x = bor(x, band(c, 255))
    x = blshift(x, 8)
    x = bor(x, d, 255)
    return x
end

-- Short Integer 32 serialization (big-endian - struct code H)
function struct.serializeShortInt32(self, v)
    local a = brshift(v, 8)
    local b = band(v, 255)
    return strchar(a, b)
end

function struct.ser_shortInt32(self, v)
    local a = band(brshift(v, 8), 255)
    local b = band(v, 255)
    return strchar(a, b)
end

-- Short Integer 32 (de-)serialization (big-endian - struct code H)
function struct.toShortInt32(self, a, b)
    local v = bor(
        blshift(band(a, 255), 8),
        band(b, 255)
    );
    return v
end

-- Calculates the checksum of integers tables
function struct.checksum(self, ...)
    local sum = {total = 0}
    foreachi(arg, function(index, value)
        %sum.total = %sum.total + value
    end)
    return band(sum.total, 65535)
end
