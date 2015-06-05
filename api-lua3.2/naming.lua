--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 26/12/2014
-- Time: 01:25
-- To change this template use File | Settings | File Templates.
--

dofile(__PATH__ .. '/api-lua3.2/core.lua')
dofile(__PATH__ .. '/api-lua3.2/constants.lua')
dofile(__PATH__ .. '/api-lua3.2/pyrouri.lua')
dofile(__PATH__ .. '/api-lua3.2/utils/debug.lua')
dofile(__PATH__ .. '/api-lua3.2/configuration.lua')
dofile(__PATH__ .. '/api-lua3.2/classes.lua')
dofile(__PATH__ .. '/api-lua3.2/exceptions.lua')

-- object (class)
NameServer = settag({URIFormatString = "PYRO:%s@%s:%d"}, newtag())

-- Method of resolution of the Message object instances
settagmethod(tag(NameServer), 'index', function(tbl, name)
    return rawgettable(NameServer, name)
end)

-- NameServer constructor
function NameServer:new(name, hmac_key)
    return settag({name=name, hmac_key=hmac_key}, tag(NameServer))
end

-- key of hmac signature(if needed)
function NameServer:set_hmac(key)
    self.hmac_key=key
end

function NameServer:locateNS(host, port, broadcast, hmac_key)
    if host == nil then
        local host = config.NS_HOST
        if not port then
            port = config.NS_PORT
        end
        local uristring = format(self.URIFormatString, constants.NAMESERVER_NAME, host, port)

        self.proxy = Proxy:new(uristring)
        self.proxy:set_hmac(self.hmac_key)

        config.LOG:debug('NAMESERVER PROXY PING RESULT', self.proxy.ping())

        return self
    end
end

function NameServer:getURI(name)
    if self.proxy == nil then
        local ns = self:locateNS() -- proxy set
    end
    local obj = self.proxy.lookup({name or self.name})
    if type(obj) == 'table' then
        if (obj['__class__'] == classes.URI) then
            local protocol = obj.state[1]
            local object = obj.state[2]
            local sockname = obj.state[3]
            local host = obj.state[4]
            local port = obj.state[5]
            return format("%s:%s@%s:%d", protocol, object, host, port)
        elseif obj['__exception__'] == 'true' then
            local error = PYROException:new(
                obj['__class__'],
                obj['args'],
                obj['kwargs'],
                obj['attributes']['_pyroTraceback']
            )
            config.LOG:debug('NAMESERVER LOOKUP ERROR', error:traceback_str())
            return error
        end
    end
    return obj
end