--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 03:48
-- To change this template use File | Settings | File Templates.
--

dofile('C:/inetpub/wwwroot/publique-repo/web/cgi/cgilua.conf/luabit-legacy/luabit-0.1/bit.lua')

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

function message.from_header(self, header)
    -- protocol is fisrt 4 caracters
    self.protocol = strsub(header, 1, 4)

    -- int version = ((header[4]&0xff)<<8) | (header[5]&0xff);
    self.version = bit.bor(
        bit.blshift(bit.band(strbyte(header, 5), 255), 8),
        bit.band(strbyte(header, 6), 255)
    );

    -- int msg_type = ((header[6]&0xff)<<8) | (header[7]&0xff);
    self.msg_type = bit.bor(
        bit.blshift(bit.band(strbyte(header, 7), 255), 8),
        bit.band(strbyte(header, 8),  255)
    )

    -- int flags = ((header[8]&0xff)<<8)|(header[9]&0xff);
    self.flags = bit.bor(
        bit.blshift(bit.band(strbyte(header, 9), 255), 8),
        bit.band(strbyte(header, 10),  255)
    )

    -- int seq = ((header[10]&0xff)<<8)|(header[11]&0xff);
    self.seq = bit.bor(
        bit.blshift(bit.band(strbyte(header, 11), 255), 8),
        bit.band(strbyte(header, 12),  255)
    )

    -- int data_size=header[12] & 0xff;
    -- data_size <<= 8;
    -- data_size |= header[13]&0xff;
    -- data_size <<= 8;
    -- data_size |= header[14]&0xff;
    -- data_size <<= 8;
    -- data_size |= header[15]&0xff;
    data_size = bit.band(strbyte(header, 13), 255)
    data_size = bit.blshift(data_size, 8)
    data_size = bit.bor(data_size, bit.band(strbyte(header, 14), 255))
    data_size = bit.blshift(data_size, 8)
    data_size = bit.bor(data_size, bit.band(strbyte(header, 15), 255))
    data_size = bit.blshift(data_size, 8)
    data_size = bit.bor(data_size, bit.band(strbyte(header, 16), 255))

    self.data_size = data_size

    -- int serializer_id = ((header[16]&0xff) << 8)|(header[17]&0xff);
    self.serializer_id = bit.bor(
        bit.blshift(bit.band(strbyte(header, 17), 255), 8),
        bit.band(strbyte(header, 18),  255)
    )

    -- int annotations_size = ((header[18]&0xff) <<8)|(header[19]&0xff);
    self.annotations_size = bit.bor(
        bit.blshift(bit.band(strbyte(header, 19), 255), 8),
        bit.band(strbyte(header, 20),  255)
    )

    -- byte 20 and 21 are reserved.

    -- int checksum = ((header[22]&0xff) << 8)|(header[23]&0xff);
    self.checksum = bit.bor(
        bit.blshift(bit.band(strbyte(header, 23), 255), 8),
        bit.band(strbyte(header, 24),  255)
    )

    -- int actual_checksum = (msg_type+version+data_size+annotations_size+flags+serializer_id+seq+CHECKSUM_MAGIC)&0xffff;
    local datasum = self.msg_type + self.version + self.data_size + self.annotations_size +
                    self.flags + self.serializer_id +  self.seq + self.CHECKSUM_MAGIC
    local actual_checksum = bit.band(datasum, 65535)
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