---
-- Class generic errors
---
PYROException = settag({}, newtag())

-- Method of resolution of the PYROException instances.
settagmethod(tag(PYROException), 'index', function(self, name)
    if rawgettable(%PYROException, name) then
        return rawgettable(%PYROException, name)
    else
        return rawgettable(self, name)
    end
end)

function PYROException:new(class, args, kwargs, traceback)
    local self = settag({}, tag(%PYROException))

    self.class = class
    self.args = args
    self.kwargs = kwargs
    self.traceback = traceback

    return self
end

function PYROException:traceback_str()
    local d = {msg = self.class .. "\n"}
    foreachi(self.traceback, function(i, v)
        %d.msg = %d.msg .. v
    end)
    return d.msg
end