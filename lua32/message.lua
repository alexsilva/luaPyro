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

    write("RECEIVED: " .. data .. " Len: " .. tostring(strlen(data)) .. "<br/>")

    local msg = self:from_header(data)
    msg.data = connection:receive(msg.data_size)

    return msg
end

function message.to_bytes(self)
--    byte[] header_bytes = get_header_bytes();
--    byte[] annotations_bytes = get_annotations_bytes();
--    byte[] result = new byte[header_bytes.length + annotations_bytes.length + data.length];
--    System.arraycopy(header_bytes, 0, result, 0, header_bytes.length);
--    System.arraycopy(annotations_bytes, 0, result, header_bytes.length, annotations_bytes.length);
--    System.arraycopy(data, 0, result, header_bytes.length+annotations_bytes.length, data.length);
--    return result;

    local header_bytes = self:get_header_bytes();
    local annotations_bytes = {}

    local size = strlen(self.data) +  1
    local i = 1
    while i < size do
        header_bytes[getn(header_bytes) + 1] = strsub(self.data, i, i)
        i = i + 1
    end

    local text = ''
    local size = getn(header_bytes) + 1
    local x = 1
    while  x < size do
        text = text .. header_bytes[x]
        x = x + 1
    end

    return text
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
--    int checksum = (type+Config.PROTOCOL_VERSION+data_size+annotations_size+serializer_id+flags+seq+CHECKSUM_MAGIC)&0xffff;

--    byte[] header = new byte[HEADER_SIZE];

--    header[0]=(byte)'P';
--    header[1]=(byte)'Y';
--    header[2]=(byte)'R';
--    header[3]=(byte)'O';
--
--    header[4]=(byte) (Config.PROTOCOL_VERSION>>8);
--    header[5]=(byte) (Config.PROTOCOL_VERSION & 0xff);
--
--    header[6]=(byte) (type>>8);
--    header[7]=(byte) (type&0xff);
--
--    header[8]=(byte) (flags>>8);
--    header[9]=(byte) (flags&0xff);
--
--    header[10]=(byte)(seq>>8);
--    header[11]=(byte)(seq & 0xff);
--
--    header[12]=(byte)((data_size>>24) & 0xff);
--    header[13]=(byte)((data_size>>16) & 0xff);
--    header[14]=(byte)((data_size>>8)  & 0xff);
--    header[15]=(byte)(data_size & 0xff);
--
--    header[16]=(byte)(serializer_id>>8);
--    header[17]=(byte)(serializer_id&0xff);
--
--    header[18]=(byte)((annotations_size>>8)&0xff);
--    header[19]=(byte)(annotations_size&0xff);
--
--    header[20]=0; // reserved
--    header[21]=0; // reserved
--
--    header[22]=(byte)((checksum>>8)&0xff);
--    header[23]=(byte)(checksum&0xff);

    self.seq = self.seq + 1 + 1

    local datasum = self.msg_type + self.version + self.data_size + self.annotations_size +
                    self.serializer_id + self.flags + self.seq + self.CHECKSUM_MAGIC
    local checksum = bit.band(datasum, 65535);

    local header = {
        'P',
        'Y',
        'R',
        'O',
        bit.brshift(47, 8),
        bit.band(47, 255),

        bit.brshift(self.msg_type, 8),
        bit.band(self.msg_type, 255),

        bit.brshift(self.flags, 8),
        bit.band(self.flags, 255),

        bit.brshift(self.seq, 8),
        bit.brshift(self.seq, 255),

        bit.band(bit.brshift(self.data_size, 24), 255),
        bit.band(bit.brshift(self.data_size, 16), 255),
        bit.band(bit.brshift(self.data_size, 8), 255),
        bit.band(self.data_size, 255),

        bit.brshift(self.serializer_id, 8),
        bit.band(self.serializer_id, 255),

        bit.band(bit.brshift(self.annotations_size, 8), 255),
        bit.band(self.annotations_size, 255),

        0,
        0,

        bit.band(bit.brshift(checksum, 8), 255),
        bit.band(checksum, 255)
    }
    return header;
end