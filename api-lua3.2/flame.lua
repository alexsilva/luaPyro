--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 30/12/2014
-- Time: 21:32
-- To change this template use File | Settings | File Templates.
--

dofile(__PATH__ .. '/api-lua3.2/message.lua')
dofile(__PATH__ .. '/api-lua3.2/classes.lua')
dofile(__PATH__ .. '/api-lua3.2/utils/debug.lua')
dofile(__PATH__ .. '/api-lua3.2/configuration.lua')
dofile(__PATH__ .. '/api-lua3.2/exceptions.lua')
dofile(__PATH__ .. '/api-lua3.2/pyrouri.lua')


---
-- class FrameBuitin(devired of Proxy)
---
FlameBuiltin = settag({}, tag(Proxy))

settagmethod(tag(FlameBuiltin), 'function', function(self, ...)
    local params = {
        self.builtin,
        arg[1] or {},
        arg[2] or {}
    }
    return self.proxy:call('invokeBuiltin', self.proxy.uri.objectid, params, {})
end)

---
-- Flame construtor
---
function FlameBuiltin:new(obj, params)
    local self = settag({}, tag(FlameBuiltin))

    self.proxy = Proxy:new(PyroURI:new(obj.flameserver.state[1]), params)
    self.builtin = obj.builtin

    return self
end

---
-- FrameModule(class)
---
FlameModule = settag({}, newtag())

settagmethod(tag(FlameModule), 'function', function(self, ...)
    local params = {
        self.module .. '.' .. self.attr,
        arg[1] or {},
        arg[2] or {}
    }
    return self.proxy:call('invokeModule', self.proxy.uri.objectid, params, {})
end)

settagmethod(tag(FlameModule), 'index', function(self, name)
    if rawgettable(FlameModule, name) then
        return rawgettable(FlameModule, name)
    elseif rawgettable(self, name) then
        return rawgettable(self, name)
    else
        return self:clone(name)
    end
end)

function FlameModule:new(obj, params)
    local self = settag({}, tag(FlameModule))

    self.proxy = Proxy:new(PyroURI:new(obj.flameserver.state[1]), params)
    self.module = obj.module
    self.attr = ""

    return self
end

function FlameModule:clone(name)
    local _self = settag({}, tag(FlameModule))
    _self.proxy = self.proxy
    if self.attr ~= "" then
        _self.module = self.module.. '.' .. self.attr
    else
        _self.module = self.module
    end
    _self.attr = name
    return _self
end