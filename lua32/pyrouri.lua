--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 23/12/14
-- Time: 10:26
-- To change this template use File | Settings | File Templates.
--

PyroURI = settag({URIPattern = "(PYRO[A-Z]*):(.+)@(%w+):(%d+)"}, newtag())

-- Method of resolution of the Pyrouri object instances.
settagmethod(tag(PyroURI), 'index', function(tbl, name)
    return rawgettable(PyroURI, name)
end)

-- PyroURI constructor
function PyroURI:new(uristring)
    local self = settag({}, tag(PyroURI))

    local i, j, protocol, objectid, loc, port = strfind(uristring, self.URIPattern)

    if not (protocol and objectid and loc and port) then
        error("invalid URI string")
    end

    self.protocol = protocol
    self.objectid = objectid
    self.loc = loc
    self.port = tonumber(port)

    return self
end