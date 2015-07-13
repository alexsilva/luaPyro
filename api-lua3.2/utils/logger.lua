--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 27/12/2014
-- Time: 20:47
-- To change this template use File | Settings | File Templates.
--

-- Log interfaces
local Log = settag({}, newtag())

settagmethod(tag(Log), "index", function(tbl, name)
    if rawgettable(%Log, name) then
        return rawgettable(%Log, name)
    else
        return rawgettable(tbl, name)
    end
end)

function Log:new(filepath)
    return settag({fmt="[%5s %s] %s ::: %s", filepath=filepath}, tag(%Log))
end

function Log:format(level, info, obj)
    return format(self.fmt, level, (date() or '00/00/00 00:00:00'), (info or 'empty'), (tostring(obj) or 'empty'))
end

function Log:write_handle(self, level, info, obj)
    return nil
end

function Log:write(level, info, obj)
    if not self:write_handle(level, info, obj) then
        local hnd = openfile(self.filepath, "a+")  -- shared resource: must be closed!
        if hnd ~= nil and hnd ~= -1 then
            write(hnd, self:format(level, info, obj).."\n")
            closefile(hnd)
        end
    end
end

function Log:debug(str, obj)
    self:write('DEBUG', str, obj)
end

function Log:info(str, obj)
    self:write('INFO', str, obj)
end

function Log:error(str, obj)
    self:write('ERROR', str, obj)
end

function Log:critical(str, obj)
    self:write('CRITICAL', str, obj)
end

return {
    Log = Log
}