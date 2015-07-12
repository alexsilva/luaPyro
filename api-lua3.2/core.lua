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
PyroProxy = settag({}, newtag())

dofile(PYRO_PATH .. package .. '/flame.lua')

---
-- Method of resolution of the proxy PyroProxy instances.
---
settagmethod(tag(PyroProxy), 'index', function(self, name)
    if rawgettable(PyroProxy, name) then
        return rawgettable(PyroProxy, name)
    elseif rawgettable(self, name) then
        return rawgettable(self, name)
    else
        return function(...)
            return %self:call(%name, %self.uri.objectid, (arg[1] or {}), (arg[2] or {}))
        end
    end
end)

---
-- PyroProxy constructor
---
function PyroProxy:new(uri, params)
    if params == nil then params = {} end
    local self = settag({}, tag(PyroProxy))

    if tag(uri) == tag(PyroURI) then
        self.uri = uri
    else
        self.uri = PyroURI:new(uri)
    end

    self.serializer = Serializer:new()
    self.params = params
    self.params.seq = params.seq or 0
    self.metadata = {}

    return self
end

function PyroProxy:set_serializer(name)
    self.serializer:set_type(name)
end

---
-- key of hmac signature(if needed)
---
function PyroProxy:set_hmac(key)
    self.params.hmac_key = key
    return self
end

---
-- Creates, initializes the proxy connection.
---
function PyroProxy:start()
    local conn, smsg = connect(self.uri.loc, self.uri.port)
    if type(conn) ~= 'userdata' then
        config.LOG:critical(format('proxy connection %s:%s', self.uri.loc, self.uri.port), smsg)
        error('PyroProxy connection failed: ' .. smsg)
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
function PyroProxy:close()
    if type(self.connection) == 'userdata' then
        self.connection:close()
        self.connection = nil
    end
end

---
-- get atribute form remote
---
function PyroProxy:getattr(name)
    return self:call("__getattr__", self.uri.objectid, {name}, {})
end

---
-- Calls the remote method
---
function PyroProxy:call(method, objectid, args, kwargs)
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
            -- Todo: check this annotations = {['CORR'] ='da82ea700fdd11e5'},
            flag = 0,
            data = data,
            seq = self.params.seq})
    self.connection:send(message:to_bytes())

    message = message:recv(self.connection, {Message.MSG_RESULT}, self.params.hmac_key)

    config.LOG:info(format('[%s] received json', method), message.data)
    local obj = self.serializer:loads(message.data)

    config.LOG:info(format('[%s] seq:%s, checksum, msgType check', method, message.seq),
        tostring(message.seq == self.params.seq + 1)..","..
        tostring(message.checksum == message.checksum_calc)..","..
        tostring(message.required_msgType_valid))

    assert(message.seq == self.params.seq + 1, 'invalid sequence!')
    assert(message.checksum == message.checksum_calc, 'checksum no match!')
    assert(message.required_msgType_valid, 'message type no match!')

    self.params.seq = message.seq

    if type(obj) == 'table' then
        if obj['flameserver'] then -- FLAME objects
            if obj["__class__"] ==  classes.FLAMEBUILTIN then
                return FlameBuiltin:new(obj, self.params)
            elseif obj["module"] then
                return FlameModule:new(obj, self.params)
            end
        elseif obj['__exception__'] then -- Exception objects
            local error = PyroException:new(
                obj['__class__'],
                obj['args'],
                obj['kwargs'],
                obj['attributes']['_pyroTraceback']
            )
            config.LOG:error('proxy call', error:traceback_str())
            return error
        end
    end
    return obj
end