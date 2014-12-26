--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 26/12/2014
-- Time: 01:25
-- To change this template use File | Settings | File Templates.
--

dofile(__path__ .. '/Pyrolite/lua32/core.lua')
dofile(__path__ .. '/Pyrolite/lua32/configuration.lua')
dofile(__path__ .. '/Pyrolite/lua32/constants.lua')
dofile(__path__ .. '/Pyrolite/lua32/pyrouri.lua')

nameserver = {}

function nameserver.locateNS(self, host, port, broadcast, hmac_key)
    if host == nill then
        local host = config.NS_HOST
        if not port then
            port = config.NS_PORT
        end
        local uristring = format("PYRO:%s@%s:%d", constants.NAMESERVER_NAME, host, port)

        self.proxy = proxy(uristring)
        self.proxy.ping()

        return self
    end
end

function nameserver.uriLookup(self, name)
    if self.proxy == nil then
        local ns = self:locateNS() -- proxy set
    end

    local uristring = self.proxy.lookup(name)

    if (type(uristring) == 'table' and uristring['__class__'] == 'Pyro4.core.URI') then
        local protocol = uristring.state[1]
        local object = uristring.state[2]
        local sockname = uristring.state[3]
        local host = uristring.state[4]
        local port = uristring.state[5]
        return format("%s:%s@%s:%d", protocol, object, host, port)
    end
end