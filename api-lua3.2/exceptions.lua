---
-- Class generic errors
---
PyroException = settag({}, newtag())

-- Method of resolution of the PyroException instances.
settagmethod(tag(PyroException), 'index', function(self, name)
    if rawgettable(%PyroException, name) then
        return rawgettable(%PyroException, name)
    else
        return rawgettable(self, name)
    end
end)

function PyroException:new(class, args, kwargs, traceback)
    local self = settag({}, tag(%PyroException))

    self.class = class
    self.args = args
    self.kwargs = kwargs
    self.traceback = traceback

    return self
end

function PyroException:traceback_str()
    local d = {msg = self.class .. "\n"}
    foreachi(self.traceback, function(i, v)
        %d.msg = %d.msg .. v
    end)
    return d.msg
end