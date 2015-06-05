--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 23/12/14
-- Time: 10:26
-- To change this template use File | Settings | File Templates.
--

PyroURI = settag({pattern = "(PYRO[A-Z]*):(.+)@(%w+):(%d+)", fmt="%s:%s@%s:%s"}, newtag())

---
-- Method of resolution of the Pyrouri object instances.
---
settagmethod(tag(PyroURI), 'index', function(self, name)
    if rawgettable(PyroURI, name) then
        return rawgettable(PyroURI, name)
    else
        return rawgettable(self, name)
    end
end)

---
-- PyroURI constructor
---
function PyroURI:new(str)
    local self = settag({}, tag(PyroURI))

    local i, j, protocol, objectid, loc, port = strfind(str, self.pattern)

    if not (protocol and objectid and loc and port) then
        error("invalid URI string")
    end

    self.protocol = protocol
    self.objectid = objectid
    self.loc = loc
    self.port = port

    return self
end

---
-- URI string format
---
function PyroURI:format(protocol, object, host, port)
    return format(self.fmt, protocol, object, host, tostring(port))
end