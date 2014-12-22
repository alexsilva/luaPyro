--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 04:11
-- To change this template use File | Settings | File Templates.
--

local package = '/Pyrolite/lua32'

dofile(__path__ .. package .. '/message.lua')
dofile(__path__ .. package ..'/serializer.lua')


proxy = {}

function proxy.create_connection(self, host, port)
    local connection, smsg = connect(host, port)

    self.connection = connection

    return message:recv(connection)
end

function proxy.call(self, methodname, args, kwargs)
    local data = serialize:dumps(nill)

    message.serializer_id = serialize.serializer_id
    message.msg_type = message.MSG_INVOKE
    message.data_size = strlen(data)
    message.data = data


    local outd = message:to_bytes()

    write("SENT: " .. outd .. " Len: " .. message.data_size .. "<br/>")

    self.connection:send(outd)

    return message:recv(self.connection)
end