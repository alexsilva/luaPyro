--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 26/12/2014
-- Time: 01:25
-- To change this template use File | Settings | File Templates.
--


dofile(__PATH__ .. '/lua32/core.lua')
dofile(__PATH__ .. '/lua32/configuration.lua')
dofile(__PATH__ .. '/lua32/constants.lua')
dofile(__PATH__ .. '/lua32/pyrouri.lua')
dofile(__PATH__ .. '/lua32/utils/debug.lua')
dofile(__PATH__ .. '/lua32/classes.lua')

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

        debug:message(self.proxy.ping(), '[ping] PROXY CALL RESULT')

        return self
    end
end

function NameServer:getURI(name)
    if self.proxy == nil then
        local ns = self:locateNS() -- proxy set
    end
    local uristring = self.proxy.lookup({name or self.name})

    if (type(uristring) == 'table' and uristring['__class__'] == classes.URI) then
        local protocol = uristring.state[1]
        local object = uristring.state[2]
        local sockname = uristring.state[3]
        local host = uristring.state[4]
        local port = uristring.state[5]
        return format("%s:%s@%s:%d", protocol, object, host, port)
    else
        debug:message(uristring, format('[%s] URI LOOKUP', (name or self.name)))
    end
end