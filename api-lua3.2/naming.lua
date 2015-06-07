--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 26/12/2014
-- Time: 01:25
-- To change this template use File | Settings | File Templates.
--

dofile(PYRO_PATH .. '/api-lua3.2/core.lua')
dofile(PYRO_PATH .. '/api-lua3.2/constants.lua')
dofile(PYRO_PATH .. '/api-lua3.2/pyrouri.lua')
dofile(PYRO_PATH .. '/api-lua3.2/utils/debug.lua')
dofile(PYRO_PATH .. '/api-lua3.2/configuration.lua')
dofile(PYRO_PATH .. '/api-lua3.2/classes.lua')
dofile(PYRO_PATH .. '/api-lua3.2/exceptions.lua')

-- object (class)
PyroNameServer = settag({}, newtag())

-- Method of resolution of the Message object instances
settagmethod(tag(PyroNameServer), 'index', function(self, name)
    if rawgettable(PyroNameServer, name) then
        return rawgettable(PyroNameServer, name)
    else
        return rawgettable(self, name)
    end
end)

-- PyroNameServer constructor
function PyroNameServer:new(name, params)
    return settag({name = name, params = params or {}}, tag(PyroNameServer))
end

-- key of hmac signature(if needed)
function PyroNameServer:set_hmac(hmac_key)
    self.params.hmac_key = hmac_key
end

function PyroNameServer:locateNS(host, port, broadcast, hmac_key)
    if host == nil then
        local host = config.NS_HOST
        if not port then
            port = config.NS_PORT
        end
        -- local hmac key set
        if hmac_key and not self.params.hmac_key then
            self.params.hmac_key = hmac_key
        end

        local uriString = PyroURI:format('PYRO', constants.NAMESERVER_NAME, host, port)

        self.proxy = PyroProxy:new(uriString, self.params)
        self.proxy.ping()

        return self
    end
end

function PyroNameServer:getURI(name)
    if self.proxy == nil then
        local ns = self:locateNS() -- proxy set
    end
    local obj = self.proxy.lookup({name or self.name})
    if type(obj) == 'table' and tag(PyroException) ~= tag(obj) and obj['__class__'] == classes.URI then
        local protocol = obj.state[1]
        local object = obj.state[2]
        local sockname = obj.state[3]
        local host = obj.state[4]
        local port = obj.state[5]
        return PyroURI:new(PyroURI:format(protocol, object, host, port))
    end
    return obj
end