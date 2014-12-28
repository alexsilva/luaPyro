--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 04:11
-- To change this template use File | Settings | File Templates.
--

local package = '/Pyrolite/lua32'

dofile(__PATH__ .. package .. '/message.lua')
dofile(__PATH__ .. package .. '/serializer.lua')
dofile(__PATH__ .. package .. '/pyrouri.lua')
dofile(__PATH__ .. package .. '/utils/debug.lua')

-- object (class)
Proxy = settag({}, newtag())


-- Method of resolution of the proxy Proxy instances.
settagmethod(tag(Proxy), 'index', function(self, name)
    if rawgettable(Proxy, name) then
        return rawgettable(Proxy, name)
    else
        return function(...)
            return %self:call(%name, (arg[1] or {}), (arg[2] or {}))
        end
    end
end)


-- Proxy constructor
function Proxy:new(uri)
    local self = settag({}, tag(Proxy))

    self.uri = PyroURI:new(uri)
    self.serializer = Serializer:new()

    self:start_connection()
    return self
end

function Proxy:set_serializer(name)
    self.serializer:set_type(name)
end

-- Creates, initializes the proxy connection.
function Proxy:start_connection()
    debug:message(smsg, 'PROXY CONNECTION')

    local conn, smsg = connect(self.uri.loc, self.uri.port)
    self.connection = conn

    return Message:recv(conn)
end

-- Close proxy connection
function Proxy:close()
    if type(self.connection) == 'userdata' then
        self.connection:close()
        self.connection = nil
    end
end

-- Calls the remote method
function Proxy:call(method, args, kwargs)
    if type(self.connection) ~= 'userdata' then
        -- connection closed ?
        self:start_connection()
    end
    local params = {
        object = self.uri.objectid,
        method = method,
        params = args,
        kwargs = kwargs
    }
    local data = self.serializer:dumps(params)
    debug:message(data, format('[%s] SENT JSON', method))

    local message = Message:new(Message.MSG_INVOKE, self.serializer:getid(), 0, data)
    self.connection:send(message:to_bytes())

    message = message:recv(self.connection)
    debug:message(message.data, format('[%s] RECEIVED JSON', method))

    return self.serializer:loads(message.data)
end