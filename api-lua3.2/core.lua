--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 04:11
-- To change this template use File | Settings | File Templates.
--

local package = '/api-lua3.2'

dofile(__PATH__ .. package .. '/message.lua')
dofile(__PATH__ .. package .. '/serializer.lua')
dofile(__PATH__ .. package .. '/pyrouri.lua')
dofile(__PATH__ .. package .. '/utils/debug.lua')
dofile(__PATH__ .. package .. '/classes.lua')
dofile(__PATH__ .. package .. '/configuration.lua')

-- object (class)
Proxy = settag({}, newtag())

dofile(__PATH__ .. package .. '/flame.lua')

-- Method of resolution of the proxy Proxy instances.
settagmethod(tag(Proxy), 'index', function(self, name)
    if rawgettable(Proxy, name) then
        return rawgettable(Proxy, name)
    else
        return function(...)
            return %self:call(%name, %self.uri.objectid, (arg[1] or {}), (arg[2] or {}))
        end
    end
end)


-- Proxy constructor
function Proxy:new(uri, params)
    if params == nil then params = {} end
    local self = settag({}, tag(Proxy))

    self.uri = PyroURI:new(uri)
    self.serializer = Serializer:new()
    self.load_metadata = params.load_metadata
    self.hmac_key = params.hmac_key
    self.metadata = {}

    return self
end

function Proxy:set_serializer(name)
    self.serializer:set_type(name)
end

-- key of hmac signature(if needed)
function Proxy:set_hmac(key)
    self.hmac_key = key
    return self
end

-- Creates, initializes the proxy connection.
function Proxy:start_connection()
    local conn, smsg = connect(self.uri.loc, self.uri.port)
    config.LOG:debug('PROXY CONNECTION MSG', smsg)

    self.connection = conn
    local message = Message:recv(conn, {Message.MSG_CONNECTOK}, self.hmac_key)

    if self.load_metadata == true or config.METADATA == true then
        self.metadata = self:call('get_metadata', config.DAEMON_NAME, {self.uri.objectid}, {})
        config.LOG:info('METADATA: ' .. self.uri.objectid, self.metadata)
    end
    return message
end

-- Close proxy connection
function Proxy:close()
    if type(self.connection) == 'userdata' then
        self.connection:close()
        self.connection = nil
    end
end

-- Calls the remote method
function Proxy:call(method, objectid, args, kwargs)
    if type(self.connection) ~= 'userdata' then
        -- connection closed ?
        self:start_connection()
    end
    local params = {
        object = objectid,
        method = method,
        params = args,
        kwargs = kwargs
    }
    local data = self.serializer:dumps(params)
    config.LOG:info(format('[%s] SENT JSON', method), data)

    -- msg_type, serializer_id, seq, data, flags, annotations, hmac_key
    local message = Message:new(Message.MSG_INVOKE, self.serializer:getid(), {
            hmac_key = self.hmac_key,
            annotations = {},
            flag = 0,
            data = data,
            seq = 0})
    self.connection:send(message:to_bytes())

    message = message:recv(self.connection, {Message.MSG_RESULT}, self.hmac_key)
    config.LOG:info(format('[%s] RECEIVED JSON', method), message.data)

    local data = self.serializer:loads(message.data)

    -- FLAME objects
    if type(data) == 'table' then
        if data["__class__"] ==  classes.FLAMEBUILTIN then
            return FlameBuiltin:new(data):set_hmac(self.hmac_key)

        elseif type(data) == 'table' and data["module"] then
            return FlameModule:new(data, {hmac_key=self.hmac_key})
        end
    end
    return data
end