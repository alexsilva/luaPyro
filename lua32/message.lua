--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 03:48
-- To change this template use File | Settings | File Templates.
--

local bitpackage = '/luabit-legacy/luabit-0.1'
local proxypackage = '/Pyrolite/lua32'

dofile(__PATH__ .. bitpackage .. '/bit.lua')
dofile(__PATH__ .. proxypackage .. '/utils/struct.lua')
dofile(__PATH__ .. proxypackage .. '/configuration.lua')

-- object (class)
Message = settag({}, newtag())

-- static attributes
Message.HEADER_SIZE = 24
Message.CHECKSUM_MAGIC = 13545
Message.MSG_CONNECT = 1
Message.MSG_CONNECTOK = 2
Message.MSG_CONNECTFAIL = 3
Message.MSG_INVOKE = 4
Message.MSG_RESULT = 5
Message.MSG_PING = 6
Message.FLAGS_EXCEPTION = bit.blshift(1, 0)
Message.FLAGS_COMPRESSED = bit.blshift(1, 1)
Message.FLAGS_ONEWAY = bit.blshift(1, 2)
Message.FLAGS_BATCH = bit.blshift(1, 3)
Message.SERIALIZER_SERPENT = 1
Message.SERIALIZER_JSON = 2
Message.SERIALIZER_MARSHAL = 3
Message.SERIALIZER_PICKLE = 4

-- Method of resolution of the Message object instances
settagmethod(tag(Message), 'index', function(tbl, name)
    return rawgettable(Message, name)
end)

--- Message constructor
function Message:new(msg_type, serializer_id, seq, data, flags, annotations, hmac_key)
    local self = settag({}, tag(Message))

    self.serializer_id = serializer_id
    self.msg_type = msg_type

    self.flags = flags or 0
    self.seq = seq or 0

    self.data = data or ''
    self.data_size = strlen(self.data)

    self.annotations = annotations or {}

    if type(hmac_key) == 'string' and strlen(hmac_key) > 0 then
        self.annotations['HMAC'] = self:hmac(hmac_key)
    end

    -- size of annotation
    local annotation = {size = 0}
    foreach(self.annotations, function(index, value)
        %annotation.size = %annotation.size + strlen(value) + 6
    end)
    self.annotations_size = annotation.size
    return self
end

function Message:from_header(headers_data)
    local message = Message:new()

    message.tag = strsub(headers_data, 1, 4) -- server tag

    message.version = struct:toShortInt32(strbyte(headers_data, 5), strbyte(headers_data, 6))

    message.msg_type = struct:toShortInt32(strbyte(headers_data, 7), strbyte(headers_data, 8))

    message.flags = struct:toShortInt32(strbyte(headers_data, 9), strbyte(headers_data, 10))

    message.seq = struct:toShortInt32(strbyte(headers_data, 11), strbyte(headers_data, 12))

    message.data_size = struct:toInt32(strbyte(headers_data, 13), strbyte(headers_data, 14),
                                    strbyte(headers_data, 15), strbyte(headers_data, 16))

    message.serializer_id = struct:toShortInt32(strbyte(headers_data, 17), strbyte(headers_data, 18))

    message.annotations_size = struct:toShortInt32(strbyte(headers_data, 19), strbyte(headers_data, 20))

    message.checksum = struct:toShortInt32(strbyte(headers_data, 23), strbyte(headers_data, 24))

    message.checksum_calc = struct:checksum(
        message.msg_type,
        message.version,
        message.data_size,
        message.annotations_size,
        message.serializer_id,
        message.flags,
        message.seq,
        message.CHECKSUM_MAGIC
    )
    return message
end

-- returns the hmac of the data and the annotation chunk values (except HMAC chunk itself)
function Message:hmac(key)
    --local mac = sha1.hmac(key, self.data)
    foreach(self.annotations, function(index, value)
        -- implement this!
    end)
    return ''
end

-- Checks whether the received message is valid type.
function Message:_check(message, required_msg_types)
    local required_msg = required_msg_types or {}
    local valid = false
    local i = 1
    while required_msg[i] ~= nil do
        if required_msg[i] == message.msg_type then
            i = getn(required_msg) -- break
            valid = true
        end
        i = i + 1
    end
    debug:message(valid, 'MESSAGE IS VALID')
    return valid
end

-- Receives a pyro message from a given connection.
-- Accepts the given message types (None=any, or pass a sequence).
-- Also reads annotation chunks and the actual payload data.
-- Validates a HMAC chunk if present.
function Message:recv(connection, required_msg_types, hmac_key)
    local header_data = connection:receive(self.HEADER_SIZE)
    local msg = self:from_header(header_data)
    -- read annotation chunks
    if msg.annotations_size > 0 then
        msg.annotations_data = connection:receive(msg.annotations_size)
        local i = 1
        while i < msg.annotations_size do
            local key = strsub(msg.annotations_data, i, i + 3)
            -- annotation value size
            local length = bit.bor(
                bit.blshift(strbyte(msg.annotations_data, i + 4), 8),
                strbyte(msg.annotations_data, i + 5))
            local annotations_bytes = strsub(msg.annotations_data, i + 6, i + 6 + length)
            msg.annotations[key] = annotations_bytes
            debug:message(msg.annotations[key], strlen(msg.annotations[key]))
            i = i + 6 + length
        end
    end
    -- read data
    msg.data = connection:receive(msg.data_size)
    self:_check(msg, required_msg_types)
    return msg
end

function Message:to_bytes()
    local header_bytes = self:get_header_bytes()
    local annotations_bytes = self:get_annotations_bytes()

    local message = {text = ""}

    foreach(header_bytes, function(index, value)
        % message.text = % message.text .. value
    end)

    foreachi(annotations_bytes, function(index, value)
        % message.text = % message.text .. value
    end)

    return message.text .. self.data
end

function Message:get_annotations_bytes()
    local chunks = {}
    foreach(self.annotations, function(key, value)
        assert(strlen(key) == 4, 'annotation key must be length 4')
        local size = getn(% chunks)
        % chunks[size + 1] = key
        % chunks[size + 2] = struct:ser_shortInt32(strlen(value))
        % chunks[size + 3] = value
    end)
    debug:message(chunks, 'chunks')
    return chunks
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
function Message:get_header_bytes()
    self.seq = self.seq + 1

    local checksum = struct:checksum(
        self.msg_type,
        config.PROTOCOL_VERSION,
        self.data_size,
        self.annotations_size,
        self.flags,
        self.serializer_id,
        self.seq,
        self.CHECKSUM_MAGIC
    )

    local headers = {
        'PYRO',
        struct:serializeShortInt32(config.PROTOCOL_VERSION),
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