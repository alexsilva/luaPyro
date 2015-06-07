--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 04:11
-- To change this template use File | Settings | File Templates.
--

local package = '/api-lua3.2'

dofile(PYRO_PATH .. package .. '/message.lua')
dofile(PYRO_PATH .. package .. '/serializer.lua')
dofile(PYRO_PATH .. package .. '/pyrouri.lua')
dofile(PYRO_PATH .. package .. '/utils/debug.lua')
dofile(PYRO_PATH .. package .. '/classes.lua')
dofile(PYRO_PATH .. package .. '/configuration.lua')
dofile(PYRO_PATH .. package .. '/exceptions.lua')

-- object (class)
PYROProxy = settag({}, newtag())

dofile(PYRO_PATH .. package .. '/flame.lua')

---
-- Method of resolution of the proxy PYROProxy instances.
---
settagmethod(tag(PYROProxy), 'index', function(self, name)
    if rawgettable(PYROProxy, name) then
        return rawgettable(PYROProxy, name)
    elseif rawgettable(self, name) then
        return rawgettable(self, name)
    else
        return function(...)
            return %self:call(%name, %self.uri.objectid, (arg[1] or {}), (arg[2] or {}))
        end
    end
end)

---
-- PYROProxy constructor
---
function PYROProxy:new(uri, params)
    if params == nil then params = {} end
    local self = settag({}, tag(PYROProxy))

    if tag(uri) == tag(PyroURI) then
        self.uri = uri
    else
        self.uri = PyroURI:new(uri)
    end

    self.serializer = Serializer:new()
    self.params = params
    self.metadata = {}

    return self
end

function PYROProxy:set_serializer(name)
    self.serializer:set_type(name)
end

---
-- key of hmac signature(if needed)
---
function PYROProxy:set_hmac(key)
    self.params.hmac_key = key
    return self
end

---
-- Creates, initializes the proxy connection.
---
function PYROProxy:start()
    local conn, smsg = connect(self.uri.loc, self.uri.port)
    if type(conn) ~= 'userdata' then
        config.LOG:critical(format('proxy connection %s:%s', self.uri.loc, self.uri.port), smsg)
        error('PYROProxy connection failed: ' .. smsg)
    end
    self.connection = conn
    local message = Message:recv(conn, {Message.MSG_CONNECTOK}, self.params.hmac_key)
    config.LOG:info(format('start connection %s:%s', self.uri.loc, self.uri.port), message.data)

    if self.params.load_metadata then
        self.metadata = self:call('get_metadata', config.DAEMON_NAME, {self.uri.objectid}, {})
    end
    return message
end

---
-- Close proxy connection
---
function PYROProxy:close()
    if type(self.connection) == 'userdata' then
        self.connection:close()
        self.connection = nil
    end
end

---
-- get atribute form remote
---
function PYROProxy:getattr(name)
    return self:call("__getattr__", self.uri.objectid, {name}, {})
end

---
-- Calls the remote method
---
function PYROProxy:call(method, objectid, args, kwargs)
    if type(self.connection) ~= 'userdata' then
        -- connection closed ?
        self:start()
    end
    local params = {
        object = objectid,
        method = method,
        params = args,
        kwargs = kwargs
    }
    local data = self.serializer:dumps(params)
    config.LOG:info(format('[%s] sent json', method), data)

    -- msg_type, serializer_id, seq, data, flags, annotations, hmac_key
    local message = Message:new(Message.MSG_INVOKE, self.serializer:getid(), {
            hmac_key = self.params.hmac_key,
            annotations = {},
            flag = 0,
            data = data,
            seq = 0})
    self.connection:send(message:to_bytes())

    message = message:recv(self.connection, {Message.MSG_RESULT}, self.params.hmac_key)

    local obj = self.serializer:loads(message.data)

    if type(obj) == 'table' then
        if obj['flameserver'] then -- FLAME objects
            if obj["__class__"] ==  classes.FLAMEBUILTIN then
                return FlameBuiltin:new(obj, self.params)
            elseif obj["module"] then
                return FlameModule:new(obj, self.params)
            end
        elseif obj['__exception__'] == 'true' then -- Exception objects
            local error = PYROException:new(
                obj['__class__'],
                obj['args'],
                obj['kwargs'],
                obj['attributes']['_pyroTraceback']
            )
            config.LOG:error('proxy call', error:traceback_str())
            return error
        end
    end
    config.LOG:info(format('[%s] received json', method), message.data)
    return obj
end