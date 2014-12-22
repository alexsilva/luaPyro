--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 03:48
-- To change this template use File | Settings | File Templates.
--

local bitpackage = '/luabit-legacy/luabit-0.1'
local proxypackage = '/Pyrolite/lua32'

dofile(__path__ .. bitpackage .. '/bit.lua')
dofile(__path__ .. proxypackage .. '/utils/struct.lua')

message = {
    HEADER_SIZE = 24,
    CHECKSUM_MAGIC = 13545,
    MSG_CONNECT = 1,
    MSG_CONNECTOK = 2,
    MSG_CONNECTFAIL = 3,
    MSG_INVOKE = 4,
    MSG_RESULT = 5,
    MSG_PING = 6,
    FLAGS_EXCEPTION = bit.blshift(1, 0),
    FLAGS_COMPRESSED = bit.blshift(1, 1),
    FLAGS_ONEWAY = bit.blshift(1, 2),
    FLAGS_BATCH = bit.blshift(1, 3),
    SERIALIZER_SERPENT = 1,
    SERIALIZER_JSON = 2,
    SERIALIZER_MARSHAL = 3,
    SERIALIZER_PICKLE = 4
}

function message.from_header(self, headers_data)
    self.tag = strsub(headers_data, 1, 4) -- server tag

    self.version = struct:toShortInt32(strbyte(headers_data, 5), strbyte(headers_data, 6))

    self.msg_type = struct:toShortInt32(strbyte(headers_data, 7), strbyte(headers_data, 8))

    self.flags = struct:toShortInt32(strbyte(headers_data, 9), strbyte(headers_data, 10))

    self.seq = struct:toShortInt32(strbyte(headers_data, 11), strbyte(headers_data, 12))

    self.data_size = struct:toInt32(strbyte(headers_data, 13), strbyte(headers_data, 14),
                                    strbyte(headers_data, 15), strbyte(headers_data, 16))

    self.serializer_id = struct:toShortInt32(strbyte(headers_data, 17), strbyte(headers_data, 18))

    self.annotations_size = struct:toShortInt32(strbyte(headers_data, 19), strbyte(headers_data, 20))

    self.checksum = struct:toShortInt32(strbyte(headers_data, 23), strbyte(headers_data, 24))

    self.checksum_calc = struct:checksum({
        self.msg_type,
        self.version,
        self.data_size,
        self.annotations_size,
        self.serializer_id,
        self.flags,
        self.seq,
        self.CHECKSUM_MAGIC
    })
    return self
end

-----
--- Args: connection, requiredMsgTypes, hmac_key
-----
function message.recv(self, connection)
    local data = connection:receive(self.HEADER_SIZE)

    local msg = self:from_header(data)
    msg.data = connection:receive(msg.data_size)

    return msg
end

function message.to_bytes(self)
    local header_bytes = self:get_header_bytes();
    local annotations_bytes = {}

    local data = {text = ""}

    foreach(header_bytes, function(i, v)
        %data.text = %data.text .. v
    end)

    return data.text .. self.data
end


--header format: '!4sHHHHiHHHH' (24 bytes)
--    4   id ('PYRO')
--    2   protocol version
--    2   message type
--    2   message flags
--    2   sequence number
--    4   data length
--    2   data serialization format (serializer id)
--    2   annotations length (total of all chunks, 0 if no annotation chunks present)
--    2   (reserved)
--    2   checksum
--followed by annotations: 4 bytes type, annotations bytes.
function message.get_header_bytes(self)
    self.seq = self.seq + 1

    local checksum = struct:checksum({
        self.msg_type,
        self.version,
        self.data_size,
        self.annotations_size,
        self.flags,
        self.serializer_id,
        self.seq,
        self.CHECKSUM_MAGIC
    })

    local headers = {
        'PYRO',
        struct:serializeShortInt32(self.version),
        struct:serializeShortInt32(self.msg_type),
        struct:serializeShortInt32(self.flags),
        struct:serializeShortInt32(self.seq),
        struct:serializeInt32(self.data_size),
        struct:serializeShortInt32(self.serializer_id),
        struct:ser_shortInt32(self.annotations_size),
        strchar(0), -- reserved
        strchar(0), -- reserved
        struct:ser_shortInt32(checksum)
    }
    return headers;
end