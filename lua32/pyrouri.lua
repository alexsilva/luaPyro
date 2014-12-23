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

settagmethod(tag(pyrouri), 'function', function(object, uri)
    local i, j, protocol, objectid, loc, port = strfind(uri, object.pattern)
    if not (protocol and objectid and loc and port) then
        error("invalid URI string")
    end
    return {
        protocol = protocol,
        objectid = objectid,
        loc = loc,
        port = tonumber(port)
    }
end)