--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 23/12/14
-- Time: 10:26
-- To change this template use File | Settings | File Templates.
--

pyrouri = {
    pattern = "(PYRO[A-Z]*):(.+)@(%w+):(%d+)"
}
settag(pyrouri, newtag())

settagmethod(tag(pyrouri), 'function', function(self, uri)
    local i, j, protocol, objectid, loc, port = strfind(uri, self.pattern)
    if not (protocol and objectid and loc and port) then
        error("invalid URI string")
    end
    self.protocol = protocol
    self.objectid = objectid
    self.loc = loc
    self.port = tonumber(port)
    return self
end)