--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 30/12/2014
-- Time: 21:32
-- To change this template use File | Settings | File Templates.
--


dofile(__PATH__ .. '/Pyrolite/lua32/message.lua')
dofile(__PATH__ .. '/Pyrolite/lua32/classes.lua')
dofile(__PATH__ .. '/Pyrolite/lua32/utils/debug.lua')


-- FrameBuitin(Proxy) - class
FrameBuitin = settag({}, tag(Proxy))

function FrameBuitin:new(params)
    assert(params.flameserver['__class__'] == classes.PROXY, 'Invalid Frame!')

    local URI = params.flameserver.state[1]
    debug:message(URI, 'FRAMESERVER URI')

    self = Proxy.new(self, URI, params)
    self.builtin = params.builtin

    -- faz o objeto chamavel
    settagmethod(tag(self), 'function', function(self, ...)
        local args = {self.builtin}
        tinsert(args, 2, arg[1])
        tinsert(args, 3, arg[2] or {})
        return self:call('invokeBuiltin', self.uri.objectid, args, {})
    end)

    return self
end


FrameModule = settag({}, tag(Proxy))

function FrameModule:new(params)
    assert(params.flameserver['__class__'] == classes.PROXY, 'Invalid Frame!')

    local URI = params.flameserver.state[1]
    debug:message(URI, 'FRAMESERVER URI')

    self = Proxy.new(self, URI, params)
    self.module = params.module

    -- faz o objeto chamavel
    settagmethod(tag(self), 'index', function(self, name)
        if rawgettable(Proxy, name) then
            return rawgettable(Proxy, name)
        else
            return function(...)
                local args = {%self.module .. '.' .. %name }

                args[2] = {arg[1] or {}}
                args[3] =  arg[2] or {}

                return %self:call('invokeModule', %self.uri.objectid, args, {})
            end
        end
    end)
    return self
end